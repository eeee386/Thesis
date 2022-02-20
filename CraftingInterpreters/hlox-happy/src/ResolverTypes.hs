{-# LANGUAGE OverloadedStrings #-}

module ResolverTypes where
  
import qualified Data.HashTable.IO as HT
import Utils
import qualified Data.Text as T
import AST
import Data.Maybe
import qualified Data.Vector as V
import EvalTypes
import NativeFunctions
import Data.List
import Data.Set

type ResolverBlockEnvironment = (HT.BasicHashTable T.Text ID)
type ResolverEnvironment = [ResolverBlockEnvironment]
type ResolverClosure = [Set TextType]

data ResolverMeta = ResolverMeta {
  resolverEnv :: ResolverEnvironment
  , currentVariableId :: Int
  , variableVector :: V.Vector EVAL
  , declarations :: [DECLARATION]
  , currentVariableInDeclaration :: Maybe TextType
  , resolverErrors :: [TextType]
  , newExpr :: EXPRESSION
  , isInFunction :: Bool
  , isInClass :: Bool
  , isInLoop :: Bool
  , closure :: ResolverClosure
} 

createNewMeta :: IO ResolverMeta
createNewMeta = do
  resEnv <- createNewResEnv
  return ResolverMeta {
    resolverEnv=resEnv
  , currentVariableId=1
  , variableVector=createGlobalVector
  , declarations=[]
  , currentVariableInDeclaration=Nothing
  , resolverErrors=[]
  , newExpr = EMPTY_EXP
  , isInFunction = False
  , isInClass = False
  , isInLoop = False
  , closure = []
  }
  
createResolverBlockEnvironment :: IO ResolverBlockEnvironment
createResolverBlockEnvironment = HT.new

addNewBlockToResEnv :: ResolverEnvironment -> IO ResolverEnvironment
addNewBlockToResEnv resEnv = do
  block <- createResolverBlockEnvironment
  return (block:resEnv)

createNewResEnv ::  IO ResolverEnvironment
createNewResEnv = addNewBlockToResEnv []

deleteBlockFromResEnv :: ResolverEnvironment -> ResolverEnvironment
deleteBlockFromResEnv resEnv = newResEnv
  where (_:newResEnv) = resEnv 
  
updateBlockInResEnv :: T.Text -> ID ->  ResolverEnvironment -> IO ResolverEnvironment
updateBlockInResEnv iden id resEnv  = do
  let (last:delResEnv) = resEnv 
  HT.insert last iden id
  return (last:delResEnv)
  
getIdOfIden :: T.Text -> ResolverBlockEnvironment -> IO (Maybe ID)
getIdOfIden iden resEnv = HT.lookup resEnv iden
  
addBlockToMeta :: ResolverMeta -> IO ResolverMeta
addBlockToMeta meta = do
  newEnv <- addNewBlockToResEnv (resolverEnv meta)
  return meta{resolverEnv=newEnv}  

deleteBlockFromMeta :: ResolverMeta -> IO ResolverMeta
deleteBlockFromMeta meta = return meta{resolverEnv=(deleteBlockFromResEnv (resolverEnv meta))}

updateBlockInMeta :: ID -> T.Text -> ResolverMeta -> IO ResolverMeta
updateBlockInMeta id iden meta = do
  newEnv <- updateBlockInResEnv iden id (resolverEnv meta)
  return meta{resolverEnv=newEnv, currentVariableInDeclaration= Just iden}
  
  
findIdInVariables :: T.Text -> ResolverMeta ->IO (Maybe ID)
findIdInVariables iden meta
  | Data.List.null resEnv = return Nothing
  | otherwise = do
    values <- mapM (getIdOfIden iden) resEnv
    let val = find isJust values
    if isJust val then return (fromJust val) else return Nothing
  where resEnv = resolverEnv meta

findIdenInMeta :: T.Text -> ResolverMeta -> IO Bool
findIdenInMeta iden meta = isJust <$> findIdInVariables iden meta

updateCurrentVariableInMeta :: ResolverMeta -> IO ResolverMeta
updateCurrentVariableInMeta meta = return meta{
  currentVariableId=currentVariableId meta+1
  , variableVector= V.snoc (variableVector meta) EVAL_NIL
}

updateClosure :: TextType -> ResolverClosure -> ResolverClosure
updateClosure iden closure = Data.Set.insert iden current:rest
  where (current:rest) = closure
  
addClosureToMeta :: ResolverMeta -> IO ResolverMeta
addClosureToMeta meta = return meta{closure=empty:closure meta}

deleteClosureFromMeta :: ResolverMeta -> IO ResolverMeta
deleteClosureFromMeta meta = return meta{closure=tail (closure meta)}

reverseDeclarationsAndErrors :: ResolverMeta -> IO ResolverMeta
reverseDeclarationsAndErrors meta = return meta{declarations=reverse (declarations meta), resolverErrors=reverse (resolverErrors meta)} 

-- Checking for closures as the values can depend on parameters, and if we have branching recursion, the running functions could rewrite the value in the global vector
checkIfDefinedForDeclaration :: TextType -> (Int -> RESOLVED_VARIABLE_DECLARATION) -> RESOLVED_VARIABLE_DECLARATION -> ResolverMeta -> IO ResolverMeta
checkIfDefinedForDeclaration iden fact factFunc meta = do
  if isInFunction meta && notElem iden (head (closure meta)) then do
    return meta{declarations=R_DEC_VAR factFunc:declarations meta, closure=updateClosure iden (closure meta)}
  else do
    let (currentResEnv:_) = resolverEnv meta
    maybeId <- getIdOfIden iden currentResEnv
    if isNothing maybeId then do
      uMeta <- updateBlockInMeta (currentVariableId meta) iden meta
      updateCurrentVariableInMeta uMeta{declarations=R_DEC_VAR (fact (currentVariableId meta)):declarations meta}
    else
      return meta{
        resolverErrors="Variable already declared in scope":resolverErrors meta
        , declarations=R_DEC_VAR (fact (-1)):declarations meta}
    
checkIfDefinedForDeclarationAndDefinition :: TextType -> (EXPRESSION -> Int -> RESOLVED_VARIABLE_DECLARATION) -> (EXPRESSION -> RESOLVED_VARIABLE_DECLARATION) -> ResolverMeta -> IO ResolverMeta
checkIfDefinedForDeclarationAndDefinition iden fact factFunc meta = checkIfDefinedForDeclaration iden (fact exp) (factFunc exp) meta
  where exp = newExpr meta
    
checkIfDefinedForDefinition :: TextType -> ResolverMeta -> IO ResolverMeta
checkIfDefinedForDefinition iden meta = do
  let exp = newExpr meta
  if isInFunction meta && any ((== True) . member iden) (closure meta) then do
    return meta{declarations=R_DEC_VAR (RC_VAR_DEF iden exp):declarations meta}
  else do
    maybeId <- findIdInVariables iden meta
    if isJust maybeId then
      return meta{declarations=R_DEC_VAR (R_VAR_DEF iden exp (fromJust maybeId)):declarations meta}
    else
      return meta{
        resolverErrors="Variable is not in scope":resolverErrors meta
        , declarations=R_DEC_VAR (R_VAR_DEF iden exp (-1)):declarations meta
      }

checkIfReferenceForDefinition :: TextType -> ResolverMeta -> IO ResolverMeta
checkIfReferenceForDefinition iden meta = do
  if isInFunction meta && any ((== True) . member iden) (closure meta) then do
    return meta{newExpr=EXP_LITERAL (R_REFERENCE_IN_CLOSURE iden)}
  else do
    maybeId <- findIdInVariables iden meta
    if isJust maybeId then
      return meta{newExpr=EXP_LITERAL (R_IDENTIFIER_REFERENCE iden (fromJust maybeId))}
    else do
      return meta{
        resolverErrors="Variable is not in scope":resolverErrors meta
        , newExpr=EXP_LITERAL (R_IDENTIFIER_REFERENCE iden (-1))}
  

-- I don't check is InFunction for functions and classes because their declarations cannot be rewritten
checkIfFunctionOrClassIsDefined :: TextType -> ResolverMeta -> IO ResolverMeta
checkIfFunctionOrClassIsDefined iden meta = do  
  let (currentResEnv:_) = resolverEnv meta
  maybeId <- getIdOfIden iden currentResEnv
  if isNothing maybeId then do
    updateBlockInMeta (currentVariableId meta) iden meta
  else
    return meta{resolverErrors="Variable already declared in scope":resolverErrors meta}
    
updateResolverErrorsByPredicate :: Bool -> TextType -> ResolverMeta -> ResolverMeta
updateResolverErrorsByPredicate predicate message meta = meta{resolverErrors=if predicate then (resolverErrors meta) else message:resolverErrors meta}