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
type ResolverClosure = [HT.BasicHashTable TextType DECLARATION]

data ResolverMeta = ResolverMeta {
  resolverEnv :: ResolverEnvironment
  , currentVariableId :: Int
  , variableVector :: V.Vector EVAL
  , declarationVector :: V.Vector DECLARATION
  , declarations :: [DECLARATION]
  , currentVariableInDeclaration :: Maybe TextType
  , resolverErrors :: [TextType]
  , newExpr :: EXPRESSION
  , isInFunction :: Bool
  , isInClass :: Bool
  , isInLoop :: Bool
  , closure :: ResolverClosure
} deriving Show

createNewMeta :: IO ResolverMeta
createNewMeta = do
  resEnv <- createNewResEnv
  return ResolverMeta {
    resolverEnv=resEnv
  , currentVariableId=1
  , variableVector=createGlobalVector
  , declarationVector=V.singleton EMPTY_DEC
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

updateCurrentVariableInMeta :: (Int -> DECLARATION) -> ResolverMeta -> ResolverMeta
updateCurrentVariableInMeta decFact meta = meta{
  declarations = decFact currId:declarations meta
  , currentVariableId=currentVariableId meta+1
  , variableVector= V.snoc (variableVector meta) EVAL_NIL
  , declarationVector = V.snoc (declarationVector meta) (decFact currId)
}
  where currId = currentVariableId meta

updateClosure :: TextType -> DECLARATION -> ResolverClosure -> IO ResolverClosure
updateClosure iden dec closure = do
  let (current:rest) = closure
  HT.insert current iden dec
  return (current:rest)
  
addClosureToMeta :: ResolverMeta -> IO ResolverMeta
addClosureToMeta meta = do
   newClosure <- HT.new
   return meta{closure=newClosure:closure meta}

deleteClosureFromMeta :: ResolverMeta -> IO ResolverMeta
deleteClosureFromMeta meta = return meta{closure=tail (closure meta)}

isInScope :: TextType -> ResolverMeta -> IO Bool
isInScope iden meta = do
  if Data.List.null (closure meta) then do
    return False
  else do
    isJust <$> HT.lookup (head (closure meta)) iden

isInClosure :: TextType -> ResolverMeta -> IO Bool
isInClosure iden meta = do
  foundElems <- mapM (`HT.lookup` iden) (closure meta)
  return (any isJust foundElems)

findInClosure :: TextType -> ResolverMeta -> IO (Maybe DECLARATION)
findInClosure iden meta = do
  foundElems <- mapM (`HT.lookup` iden) (closure meta)
  if any isJust foundElems then do
    return (fromJust (find isJust foundElems))
  else do
    return Nothing

reverseDeclarationsAndErrors :: ResolverMeta -> IO ResolverMeta
reverseDeclarationsAndErrors meta = return meta{declarations=reverse (declarations meta), resolverErrors=reverse (resolverErrors meta)} 

-- Checking for closures as the values can depend on parameters, and if we have branching recursion, the running functions could rewrite the value in the global vector
checkIfDefinedForDeclaration :: TextType -> (Int -> RESOLVED_VARIABLE_DECLARATION) -> RESOLVED_VARIABLE_DECLARATION -> ResolverMeta -> IO ResolverMeta
checkIfDefinedForDeclaration iden fact factFunc meta = do
  inScope <- isInScope iden meta
  if isInFunction meta && inScope then do
    newClosure <- updateClosure iden (R_DEC_VAR factFunc) (closure meta)
    return meta{declarations=R_DEC_VAR factFunc:declarations meta, closure=newClosure}
  else do
    let (currentResEnv:_) = resolverEnv meta
    maybeId <- getIdOfIden iden currentResEnv
    if isNothing maybeId then do
      uMeta <- updateBlockInMeta (currentVariableId meta) iden meta
      return (updateCurrentVariableInMeta (R_DEC_VAR . fact) uMeta)
    else
      return meta{
        resolverErrors="Variable already declared in scope":resolverErrors meta
        , declarations=R_DEC_VAR (fact (-1)):declarations meta}
    
checkIfDefinedForDeclarationAndDefinition :: TextType -> (EXPRESSION -> Int -> RESOLVED_VARIABLE_DECLARATION) -> (EXPRESSION -> RESOLVED_VARIABLE_DECLARATION) -> ResolverMeta -> IO ResolverMeta
checkIfDefinedForDeclarationAndDefinition iden fact factFunc meta = checkIfDefinedForDeclaration iden (fact exp) (factFunc exp) meta
  where exp = newExpr meta

-- Checking both that the variable exists, and that the variable is not a functions I don't want people to redeclare functions/classes as simple variables
checkIfDefinedForDefinition :: TextType -> ResolverMeta -> IO ResolverMeta
checkIfDefinedForDefinition iden meta = do
  let exp = newExpr meta
  maybeDec <- findInClosure iden meta
  if isInFunction meta && isJust maybeDec then do
    if isVariableDeclaration (fromJust maybeDec) then do
      return meta{declarations=R_DEC_VAR (RC_VAR_DEF iden exp):declarations meta}
    else do
      return meta{
        resolverErrors="This is not a variable declaration":resolverErrors meta
        , declarations=R_DEC_VAR (RC_VAR_DEF iden exp):declarations meta
      }
  else do
    maybeId <- findIdInVariables iden meta
    if isJust maybeId then do
      print (declarationVector meta)
      print (fromJust maybeId)
      if isVariableDeclaration (declarationVector meta V.! fromJust maybeId) then do
        return meta{declarations=R_DEC_VAR (R_VAR_DEF iden exp (fromJust maybeId)):declarations meta}
      else do
        return meta{
          resolverErrors="This is not a variable declaration":resolverErrors meta
          , declarations=R_DEC_VAR (R_VAR_DEF iden exp (-1)):declarations meta
        }
    else
      return meta{
        resolverErrors="Variable is not in scope":resolverErrors meta
        , declarations=R_DEC_VAR (R_VAR_DEF iden exp (-1)):declarations meta
      }

-- Here I only check but I don't create it
checkIfReferenceForDefinition :: TextType -> (Int -> EXPRESSION) -> EXPRESSION -> ResolverMeta -> IO ResolverMeta
checkIfReferenceForDefinition iden factExp funcExp meta = do
  inClosure <- isInClosure iden meta
  if isInFunction meta && inClosure then do
    return meta{newExpr=funcExp}
  else do
    maybeId <- findIdInVariables iden meta
    if isJust maybeId then
      return meta{newExpr=factExp (fromJust maybeId)}
    else do
      return meta{
        resolverErrors="Variable is not in scope":resolverErrors meta
        , newExpr=factExp (-1)}

checkIfCallReferenceForDefinition :: TextType -> (Int -> EXPRESSION) -> EXPRESSION -> ResolverMeta -> IO ResolverMeta
checkIfCallReferenceForDefinition iden factExp funcExp meta = do
  print "is called"
  maybeDec <- findInClosure iden meta
  if isInFunction meta && isJust maybeDec then do
    if not (isVariableDeclaration (fromJust maybeDec)) then do
      return meta{newExpr=funcExp}
    else do
      return meta{
        resolverErrors="Not a function call":resolverErrors meta
      , newExpr=funcExp}
  else do
    maybeId <- findIdInVariables iden meta
    if isJust maybeId then do
      print (declarationVector meta V.! fromJust maybeId)
      if not (isVariableDeclaration (declarationVector meta V.! fromJust maybeId)) then do
        return meta{newExpr=factExp (fromJust maybeId)}
      else do
        return meta{
          resolverErrors="Not a function call":resolverErrors meta
        , newExpr=factExp (-1)}
    else do
      return meta{
        resolverErrors="Variable is not in scope":resolverErrors meta
        , newExpr=factExp (-1)}
  
isFunctionOrClass :: DECLARATION -> Bool
isFunctionOrClass (DEC_FUNC _) = True
isFunctionOrClass (DEC_CLASS _) = True
isFunctionOrClass (R_DEC_CLASS _) = True
isFunctionOrClass _ = False

checkIfFunctionOrClassIsDefined :: TextType -> DECLARATION -> ResolverMeta  -> IO ResolverMeta
checkIfFunctionOrClassIsDefined iden dec meta = do
  if isInFunction meta then do
    inClosure <- isInClosure iden meta
    if inClosure then do
      return meta{resolverErrors="Variable already declared in scope":resolverErrors meta}
    else do
      newClosure <- updateClosure iden dec (closure meta)
      return meta{closure=newClosure, declarations=dec:declarations meta}
  else do
    let (currentResEnv:_) = resolverEnv meta
    maybeId <- getIdOfIden iden currentResEnv
    if isNothing maybeId then do
      newMeta <- updateBlockInMeta (currentVariableId meta) iden meta
      return newMeta
    else
      return meta{resolverErrors="Variable already declared in scope":resolverErrors meta}
    
updateResolverErrorsByPredicate :: Bool -> TextType -> ResolverMeta -> ResolverMeta
updateResolverErrorsByPredicate predicate message meta = meta{resolverErrors=if predicate then resolverErrors meta else message:resolverErrors meta}