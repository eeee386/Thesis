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

type ResolverBlockEnvironment = (HT.BasicHashTable T.Text Int)
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
  , isInSubClass :: Bool
  , isInLoop :: Bool
  , closure :: ResolverClosure
  , currentFunctionName :: TextType
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
  , isInSubClass = False
  , isInLoop = False
  , closure = []
  , currentFunctionName = ""
  }
  
isInFunctionOrClass :: ResolverMeta -> Bool
isInFunctionOrClass meta = isInFunction meta || isInClass meta

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
  
updateBlockInResEnv :: T.Text -> Int ->  ResolverEnvironment -> IO ResolverEnvironment
updateBlockInResEnv iden id resEnv  = do
  let (last:delResEnv) = resEnv 
  HT.insert last iden id
  return (last:delResEnv)
  
getIdOfIden :: T.Text -> ResolverBlockEnvironment -> IO (Maybe Int)
getIdOfIden iden resEnv = HT.lookup resEnv iden
  
addBlockToMeta :: ResolverMeta -> IO ResolverMeta
addBlockToMeta meta = do
  newEnv <- addNewBlockToResEnv (resolverEnv meta)
  return meta{resolverEnv=newEnv}  

deleteBlockFromMeta :: ResolverMeta -> IO ResolverMeta
deleteBlockFromMeta meta = return meta{resolverEnv=(deleteBlockFromResEnv (resolverEnv meta))}

updateBlockInMeta :: Int -> T.Text -> ResolverMeta -> IO ResolverMeta
updateBlockInMeta id iden meta = do
  newEnv <- updateBlockInResEnv iden id (resolverEnv meta)
  return meta{resolverEnv=newEnv, currentVariableInDeclaration= Just iden}
  
  
findIdInVariables :: T.Text -> ResolverMeta ->IO (Maybe Int)
findIdInVariables iden meta
  | Data.List.null resEnv = return Nothing
  | otherwise = do
    values <- mapM (getIdOfIden iden) resEnv
    let val = find isJust values
    if isJust val then return (fromJust val) else return Nothing
  where resEnv = resolverEnv meta

findIdenInMeta :: T.Text -> ResolverMeta -> IO Bool
findIdenInMeta iden meta = isJust <$> findIdInVariables iden meta

updateCurrentVariableInMeta :: TextType -> (ID -> DECLARATION) -> ResolverMeta -> IO ResolverMeta
updateCurrentVariableInMeta iden decFact meta = do
  newMeta <- updateBlockInMeta currId iden meta
  return newMeta{
  declarations = decFact (ID currId):declarations meta
  , currentVariableId=currentVariableId meta+1
  , variableVector= V.snoc (variableVector meta) EVAL_NIL
  , declarationVector = V.snoc (declarationVector meta) (decFact (ID currId))
}
  where currId = currentVariableId meta

updateClosure :: TextType -> DECLARATION -> ResolverClosure -> IO ResolverClosure
updateClosure iden dec closure = do
  let (current:rest) = closure
  HT.insert current iden dec
  return (current:rest)

updateClosureInMeta :: TextType -> DECLARATION -> ResolverMeta -> IO ResolverMeta
updateClosureInMeta iden dec meta = do
  newClosure <- updateClosure iden dec (closure meta)
  return meta{closure=newClosure, declarations=dec:declarations meta}

  
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
checkIfDefinedForDeclaration :: TextType -> (ID -> DECLARATION) -> DECLARATION -> ResolverMeta -> IO ResolverMeta
checkIfDefinedForDeclaration iden fact factFunc meta = do
  inScope <- isInScope iden meta
  if isInFunctionOrClass meta && inScope then do
    updateClosureInMeta iden factFunc meta
  else do
    let (currentResEnv:_) = resolverEnv meta
    maybeId <- getIdOfIden iden currentResEnv
    if isNothing maybeId then do
      updateCurrentVariableInMeta iden fact meta
    else
      return meta{
        resolverErrors="Variable already declared in scope":resolverErrors meta
        , declarations=fact NON_ID:declarations meta}
    
checkIfDefinedForDeclarationAndDefinition :: TextType -> (EXPRESSION -> ID -> DECLARATION) -> (EXPRESSION -> DECLARATION) -> ResolverMeta -> IO ResolverMeta
checkIfDefinedForDeclarationAndDefinition iden fact factFunc meta = checkIfDefinedForDeclaration iden (fact exp) (factFunc exp) meta
  where exp = newExpr meta

-- Checking both that the variable exists, and that the variable is not a functions I don't want people to redeclare functions/classes as simple variables
checkIfDefinedForDefinition :: TextType -> (ID -> DECLARATION) -> DECLARATION -> ResolverMeta -> IO ResolverMeta
checkIfDefinedForDefinition iden decFact dec meta = do
  maybeDec <- findInClosure iden meta
  if isInFunctionOrClass meta && isJust maybeDec then do
    if not (isCallable iden (fromJust maybeDec) meta) then do
      return meta{declarations=dec:declarations meta}
    else do
      return meta{
        resolverErrors="This is not a variable declaration":resolverErrors meta
        , declarations=dec:declarations meta
      }
  else do
    maybeId <- findIdInVariables iden meta
    if isJust maybeId then do
      if not (isCallable iden (declarationVector meta V.! fromJust maybeId) meta) then do
        return meta{declarations=decFact (ID (fromJust maybeId)):declarations meta}
      else do
        return meta{
          resolverErrors="This is not a variable declaration":resolverErrors meta
          , declarations=decFact NON_ID:declarations meta
        }
    else
      return meta{
        resolverErrors="Variable is not in scope":resolverErrors meta
        , declarations=decFact NON_ID:declarations meta
      }

checkIfDefinedForDefinitionWithExpr :: TextType -> (EXPRESSION -> ID -> DECLARATION) -> (EXPRESSION -> DECLARATION) -> ResolverMeta -> IO ResolverMeta
checkIfDefinedForDefinitionWithExpr iden decFact dec meta = checkIfDefinedForDefinition iden (decFact expr) (dec expr) meta
  where expr = newExpr meta

-- Here I only check but I don't create it
checkIfReferenceForDefinition :: TextType -> (ID -> EXPRESSION) -> EXPRESSION -> ResolverMeta -> IO ResolverMeta
checkIfReferenceForDefinition iden factExp funcExp meta = do
  inClosure <- isInClosure iden meta
  if isInFunctionOrClass meta && inClosure then do
    return meta{newExpr=funcExp}
  else do
    maybeId <- findIdInVariables iden meta
    if isJust maybeId then
      return meta{newExpr=factExp (ID (fromJust maybeId))}
    else do
      return meta{
        resolverErrors="Variable is not in scope":resolverErrors meta
        , newExpr=factExp NON_ID}

checkIfCallReferenceForDefinition :: TextType -> (ID -> EXPRESSION) -> EXPRESSION -> ResolverMeta -> IO ResolverMeta
checkIfCallReferenceForDefinition iden factExp funcExp meta = do
  maybeDec <- findInClosure iden meta
  if isInFunctionOrClass meta && isJust maybeDec then do
    if isCallable iden (fromJust maybeDec) meta then do
      return meta{newExpr=funcExp}
    else do
      return meta{
        resolverErrors="Not a function call":resolverErrors meta
      , newExpr=funcExp}
  else do
    maybeId <- findIdInVariables iden meta
    if isJust maybeId then do
      print (declarationVector meta V.! fromJust maybeId)
      if isCallable iden (declarationVector meta V.! fromJust maybeId) meta then do
        return meta{newExpr=factExp (ID (fromJust maybeId))}
      else do
        return meta{
          resolverErrors="Not a function call":resolverErrors meta
        , newExpr=factExp NON_ID}
    else do
      return meta{
        resolverErrors="Variable is not in scope":resolverErrors meta
        , newExpr=factExp NON_ID}
  
isFunctionOrClass :: DECLARATION -> Bool
isFunctionOrClass (DEC_FUNC _) = True
isFunctionOrClass (DEC_CLASS _) = True
isFunctionOrClass (R_DEC_CLASS _) = True
isFunctionOrClass _ = False

checkIfFunctionOrClassIsDefinedAndSaveEmpty :: TextType -> ResolverMeta -> IO (ID, ResolverMeta)
checkIfFunctionOrClassIsDefinedAndSaveEmpty iden meta = do
  if isInFunctionOrClass meta then do
    inClosure <- isInClosure iden meta
    if inClosure then do
      return (NON_ID, meta{resolverErrors="Variable already declared in scope":resolverErrors meta})
    else do
      newMeta <- updateClosureInMeta iden EMPTY_DEC meta 
      return (NON_ID, newMeta)
  else do
    let (currentResEnv:_) = resolverEnv meta
    maybeId <- getIdOfIden iden currentResEnv
    if isNothing maybeId then do
      print iden
      print EMPTY_DEC
      print currId
      newMeta <- updateCurrentVariableInMeta iden (const EMPTY_DEC) meta
      return (ID currId, newMeta)
    else
      return (NON_ID, meta{resolverErrors="Variable already declared in scope":resolverErrors meta})
  where currId = currentVariableId meta

updateFunctionOrClassDeclaration :: ID -> TextType -> DECLARATION -> ResolverMeta -> IO ResolverMeta
updateFunctionOrClassDeclaration id iden dec meta = do
  if isInFunctionOrClass meta then do
    updateClosureInMeta iden dec meta
  else do
    let (ID val) = id
    return meta{declarations=dec:declarations meta, declarationVector=V.update (declarationVector meta) (V.fromList [(val,dec)])}

    
updateResolverErrorsByPredicate :: Bool -> TextType -> ResolverMeta -> ResolverMeta
updateResolverErrorsByPredicate predicate message meta = meta{resolverErrors=if predicate then resolverErrors meta else message:resolverErrors meta}


isCallOrFuncDecOrClassDec :: DECLARATION -> Bool
isCallOrFuncDecOrClassDec (R_DEC_VAR (R_VAR_DEC_DEF _ (EXP_CALL _) _)) = True
isCallOrFuncDecOrClassDec (R_DEC_VAR (R_VAR_DEF _ (EXP_CALL _) _)) = True
isCallOrFuncDecOrClassDec (R_DEC_VAR (RC_VAR_DEC_DEF _ (EXP_CALL _))) = True
isCallOrFuncDecOrClassDec (R_DEC_VAR (RC_VAR_DEF _ (EXP_CALL _))) = True
isCallOrFuncDecOrClassDec (DEC_FUNC _) = True
isCallOrFuncDecOrClassDec (R_DEC_CLASS _) = True
isCallOrFuncDecOrClassDec _ = False

isCallable :: TextType -> DECLARATION -> ResolverMeta -> Bool
isCallable iden dec meta = currentFunctionName meta == iden || isCallOrFuncDecOrClassDec dec
