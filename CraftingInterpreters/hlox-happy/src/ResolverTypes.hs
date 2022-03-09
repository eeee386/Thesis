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
  -- A list of map to check indexed variables
  --   - for a variable declaration we will check if we have any with the same in the current envieroment -> if we have error, if we don't save it with the id (currentVariableId) 
  --   - for a indexed reference, we will go up the resolver env find the closest variable and use its id to be id of the reference
  -- this is a solution for the following problem {var a = 5;} {a = 4;} print a; -> for every new block a new block env is created , and if a block is resolved, then it is deleted
  resolverEnv :: ResolverEnvironment
  -- This property will be the indexed variable's id, and the variable's index in the variableVector and declarationVector
  , currentVariableId :: Int
  -- An array where we save a new empty eval for an new variable declaration
  -- In the eval, we update them (so a "var a = 4 (ID 4)" is saved in the resolver as a EMPTY_EVAL, but in the evaluation it will updated to "EVAL_NUMBER 4")
  , variableVector :: V.Vector EVAL
  -- An array where we save the new indexed variables' declaration, for checking types (if callable or not) when doing resolution
  , declarationVector :: V.Vector DECLARATION
  -- The current scope's declaration or the global declarations depending what scope are we in.
  , declarations :: [DECLARATION]
  -- All the errors are collected here
  , resolverErrors :: [TextType]
  -- This is a helper for resolving more complex expression 
  -- (expressions are a tree -> from the "root expr" we call the child expr and we save it here, the more complex expr take the resolved, and puts themselves in this property)
  , newExpr :: EXPRESSION
  -- Is in function: helps to check if we need to check the indexed variables or the closure variables, and to check if we call the "return" properly
  -- If true check in closure and returns are valid, if not check in indexed variables and returns are not valid
  , isInFunction :: Bool
    -- Is in function: helps to check if we need to check the indexed variables or the closure variables, and to check if we call the "this" properly
    -- If true check in closure and "this" are valid, if not check in indexed variables and "this" are not valid
  , isInClass :: Bool
  -- Only used with "isInClass", but if this is true "super" is valid
  , isInSubClass :: Bool
  -- To check if "break" and "continue" are valid
  , isInLoop :: Bool
  -- a list of hashtables where we save closure variables, and in the reference resolution checking their types (callable or not)
  , closure :: ResolverClosure
  -- A helper for self recursion.
  -- we don't save the resolved declaration only after we did the body declarations, 
  -- so we save this property and know when it is referenced it should not be looked up, but checked with this
  , currentFunctionName :: TextType
} deriving Show

createNewMeta :: IO ResolverMeta
createNewMeta = do
  resEnv <- createNewResEnv
  return ResolverMeta {
    resolverEnv=resEnv
  , currentVariableId=1
  , variableVector=createGlobalVector
  , declarationVector=createGlobalDeclaration
  , declarations=[]
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

-- Add a new block for the indexed variable checking
addNewBlockToResEnv :: ResolverEnvironment -> IO ResolverEnvironment
addNewBlockToResEnv resEnv = do
  block <- createResolverBlockEnvironment
  return (block:resEnv)

-- Create the global block environment (+ add clock native function)
createGlobalResolverBlockEnvironment :: IO ResolverBlockEnvironment
createGlobalResolverBlockEnvironment = do
  table <- HT.new
  HT.insert table "clock" 0
  return table


createNewResEnv ::  IO ResolverEnvironment
createNewResEnv = do 
  newEnv <- createGlobalResolverBlockEnvironment
  addNewBlockToResEnv [newEnv]

deleteBlockFromResEnv :: ResolverEnvironment -> ResolverEnvironment
deleteBlockFromResEnv resEnv = newResEnv
  where (_:newResEnv) = resEnv 
  
updateBlockInResEnv :: T.Text -> Int ->  ResolverEnvironment -> IO ResolverEnvironment
updateBlockInResEnv iden id resEnv  = do
  let (last:delResEnv) = resEnv 
  HT.insert last iden id
  return (last:delResEnv)

-- If we are not in a closure (not in function or class)
-- find the id (index in the variableVector/declarationVector)
getIdOfIden :: T.Text -> ResolverBlockEnvironment -> IO (Maybe Int)
getIdOfIden iden resEnv = HT.lookup resEnv iden
  
addBlockToMeta :: ResolverMeta -> IO ResolverMeta
addBlockToMeta meta = do
  newEnv <- addNewBlockToResEnv (resolverEnv meta)
  return meta{resolverEnv=newEnv}  

deleteBlockFromMeta :: ResolverMeta -> IO ResolverMeta
deleteBlockFromMeta meta = return meta{resolverEnv=deleteBlockFromResEnv (resolverEnv meta)}

updateBlockInMeta :: Int -> T.Text -> ResolverMeta -> IO ResolverMeta
updateBlockInMeta id iden meta = do
  newEnv <- updateBlockInResEnv iden id (resolverEnv meta)
  return meta{resolverEnv=newEnv}
  
  
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

-- This is needed as we save the declarations and errors as a list, and the earliest is the last
reverseDeclarationsAndErrors :: ResolverMeta -> IO ResolverMeta
reverseDeclarationsAndErrors meta = return meta{declarations=reverse (declarations meta), resolverErrors=reverse (resolverErrors meta)} 

-- We check if the variable can be declared (if it does not exists yet)
-- Checking for closures as the values can depend on parameters, and if we have branching recursion, the running functions could rewrite the value in the global vector
checkIfDefinedForDeclaration :: TextType -> (ID -> DECLARATION) -> DECLARATION -> ResolverMeta -> IO ResolverMeta
checkIfDefinedForDeclaration iden fact factFunc meta = do
  inScope <- isInScope iden meta
  if isInFunctionOrClass meta && not inScope then do
    updateClosureInMeta iden factFunc meta
  else do
    let (currentResEnv:_) = resolverEnv meta
    maybeId <- getIdOfIden iden currentResEnv
    if isNothing maybeId then do
      updateCurrentVariableInMeta iden fact meta
    else do
      return meta{
        resolverErrors="Variable already declared in scope":resolverErrors meta
        , declarations=fact NON_ID:declarations meta}
    
checkIfDefinedForDeclarationAndDefinition :: TextType -> (EXPRESSION -> ID -> DECLARATION) -> (EXPRESSION -> DECLARATION) -> ResolverMeta -> IO ResolverMeta
checkIfDefinedForDeclarationAndDefinition iden fact factFunc meta = checkIfDefinedForDeclaration iden (fact exp) (factFunc exp) meta
  where exp = newExpr meta

-- Checking both that the variable exists, and that the variable is not a function or a class dec. 
-- I don't want people to redeclare functions/classes as simple variables, vice versa
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

-- Same as above, but the declaration here has an expression as well, and we call the above function, after we add the expression
checkIfDefinedForDefinitionWithExpr :: TextType -> (EXPRESSION -> ID -> DECLARATION) -> (EXPRESSION -> DECLARATION) -> ResolverMeta -> IO ResolverMeta
checkIfDefinedForDefinitionWithExpr iden decFact dec meta = checkIfDefinedForDefinition iden (decFact expr) (dec expr) meta
  where expr = newExpr meta

-- Check if the variable/class/function "a" already exists
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

-- if we have "a(...)", check if the "a" exists, and it is a function
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

-- In this function we save the class and function placeholder declaration,
-- Here we check if we already declared a function or a class with this name,
-- And save a dummy declaration.
-- We need to save a dummy declaration, as we don't have the function or class bodies' inner declarations
-- And I thought it was easier to save a dummy, send back the ID and if we have the inner declarations resolved
-- we update the declaration in "updateFunctionOrClassDeclaration"
checkIfFunctionOrClassIsDefinedAndSaveEmpty :: TextType -> ResolverMeta -> IO (ID, ResolverMeta)
checkIfFunctionOrClassIsDefinedAndSaveEmpty iden meta = do
  if isInFunctionOrClass meta then do
    inScope <- isInScope iden meta
    if inScope then do
      return (NON_ID, meta{resolverErrors="Function/class already declared in scope":resolverErrors meta})
    else do
      newMeta <- updateClosureInMeta iden EMPTY_DEC meta 
      return (NON_ID, newMeta)
  else do
    let (currentResEnv:_) = resolverEnv meta
    maybeId <- getIdOfIden iden currentResEnv
    if isNothing maybeId then do
      newMeta <- updateCurrentVariableInMeta iden (const EMPTY_DEC) meta
      return (ID currId, newMeta)
    else
      return (NON_ID, meta{resolverErrors="Function/class already declared in scope":resolverErrors meta})
  where currId = currentVariableId meta

-- This function purpose is to save the actual the final resolved declaration of the class or the function, after its has been resolved
-- The NON_ID case is an error, but because the resolver is created before hand in the "checkIfFunctionOrClassIsDefinedAndSaveEmpty" function
-- We will not update the resolver errors here
updateFunctionOrClassDeclaration :: ID -> TextType -> DECLARATION -> ResolverMeta -> IO ResolverMeta
updateFunctionOrClassDeclaration id iden dec meta = do
  if isInFunctionOrClass meta then do
    updateClosureInMeta iden dec meta
  else do
    case id of
       (ID val) -> return meta{declarations=dec:declarations meta, declarationVector=V.update (declarationVector meta) (V.fromList [(val,dec)])}
       NON_ID -> return meta{declarations=dec:declarations meta}
    


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
