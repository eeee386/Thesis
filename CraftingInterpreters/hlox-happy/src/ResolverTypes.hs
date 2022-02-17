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

type ResolverBlockEnvironment = (HT.BasicHashTable T.Text ID)
type ResolverEnvironment = [ResolverBlockEnvironment]

data ResolverMeta = ResolverMeta {
  resolverEnv :: ResolverEnvironment
  , currentVariableId :: Int
  , variableVector :: V.Vector EVAL
  , declarations :: [DECLARATION]
  , currentVariableInDeclaration :: Maybe TextType
  , resolverErrors :: [TextType]
  , newExpr :: EXPRESSION
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
  , newExpr = NON_EXP
  }
  
createResolverBlockEnvironment :: IO ResolverBlockEnvironment
createResolverBlockEnvironment = HT.new

addNewBlockToResEnv :: ResolverEnvironment -> IO ResolverEnvironment
addNewBlockToResEnv resEnv = do
  block <- createResolverBlockEnvironment
  return (block:resEnv)

createNewResEnv ::  IO ResolverEnvironment
createNewResEnv = addNewBlockToResEnv createStack

deleteBlockFromResEnv :: ResolverEnvironment -> ResolverEnvironment
deleteBlockFromResEnv resEnv = newResEnv
  where (_,newResEnv) = pop resEnv 
  
updateBlockInResEnv :: T.Text -> ID ->  ResolverEnvironment -> IO ResolverEnvironment
updateBlockInResEnv iden id resEnv  = do
  let (last, delResEnv) = pop resEnv 
  HT.insert last iden id
  return (push last delResEnv)
  
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
  | null resEnv = return Nothing
  | otherwise = do
    values <- mapM (getIdOfIden iden) resEnv
    let val = find isJust values
    if isJust val then return (fromJust val) else return Nothing
  where resEnv = resolverEnv meta

findIdenInMeta :: T.Text -> ResolverMeta -> IO Bool
findIdenInMeta iden meta = isJust <$> findIdInVariables iden meta
  

reverseDeclarationsAndErrors :: ResolverMeta -> IO ResolverMeta
reverseDeclarationsAndErrors meta = return meta{declarations=reverse (declarations meta), resolverErrors=reverse (resolverErrors meta)} 


checkIfDefinedForDeclaration :: TextType -> (Int -> RESOLVED_VARIABLE_DECLARATION) -> ResolverMeta -> IO ResolverMeta
checkIfDefinedForDeclaration iden fact meta = do
  let (currentResEnv:_) = resolverEnv meta
  maybeId <- getIdOfIden iden currentResEnv
  if isNothing maybeId then do
    uMeta <- updateBlockInMeta (currentVariableId meta) iden meta
    return uMeta{declarations=(R_DEC_VAR (fact (currentVariableId meta))):(declarations meta), currentVariableId=currentVariableId meta+1, variableVector= V.snoc (variableVector meta) EVAL_NIL}
  else 
    return meta{resolverErrors="Variable already declared in scope":(resolverErrors meta)}
    
checkIfDefinedForDeclarationAndDefinition :: TextType -> (EXPRESSION -> Int -> RESOLVED_VARIABLE_DECLARATION) -> ResolverMeta -> IO ResolverMeta
checkIfDefinedForDeclarationAndDefinition iden fact meta = checkIfDefinedForDeclaration iden (fact exp) meta
  where exp = newExpr meta
    
checkIfDefinedForDefinition :: TextType -> ResolverMeta -> IO ResolverMeta
checkIfDefinedForDefinition iden meta = do
  let exp = newExpr meta
  let (currentResEnv:_) = resolverEnv meta
  maybeId <- getIdOfIden iden currentResEnv
  if isJust maybeId then 
    return meta{declarations=(R_DEC_VAR (R_VAR_DEF iden exp (fromJust maybeId)):(declarations meta))}
  else 
    return meta{resolverErrors="Variable is not in scope":resolverErrors meta}

checkIfReferenceForDefinition :: TextType -> ResolverMeta -> IO ResolverMeta
checkIfReferenceForDefinition iden meta = do
  maybeId <- findIdInVariables iden meta
  vals <- (mapM HT.toList (resolverEnv meta))
  if isJust maybeId then
    return meta{newExpr=EXP_LITERAL (R_IDENTIFIER_REFERENCE iden (fromJust maybeId))}
  else
    return meta{resolverErrors="Value is not in scope":resolverErrors meta}
    

   
                          
{-
-- ResolverError
data ResolverError = RESOLVER_ERROR T.Text (S.Seq TH.Token) deriving Show

-- Function Types
data FunctionTypes = NONE | FUNCTION | METHOD deriving (Show, Eq)

-- Resolver Environment
type ResolverBlockEnvironment = HT.BasicHashTable T.Text ID

type ResolverEnvironment = Stack ResolverBlockEnvironment

createResolverBlockEnvironment :: IO ResolverBlockEnvironment
createResolverBlockEnvironment = HT.new

addNewBlockToResEnv :: ResolverEnvironment -> IO ResolverEnvironment
addNewBlockToResEnv resEnv = do
  block <- createResolverBlockEnvironment
  return (push block resEnv)

createNewResEnv ::  IO ResolverEnvironment
createNewResEnv = addNewBlockToResEnv createStack

deleteBlockFromResEnv :: ResolverEnvironment -> ResolverEnvironment
deleteBlockFromResEnv resEnv = newResEnv
  where (_,newResEnv) = pop resEnv 

updateBlockInResEnv :: T.Text -> ID ->  ResolverEnvironment -> IO ResolverEnvironment
updateBlockInResEnv iden id resEnv  = do
  let (last, delResEnv) = pop resEnv 
  HT.insert last iden id
  return (push last delResEnv)

getIdOfIden :: T.Text -> ResolverBlockEnvironment -> IO (Maybe ID)
getIdOfIden iden resEnv = HT.lookup resEnv iden


-- ResolverMeta
data ResolverMeta = ResolverMeta {
   varIden :: Maybe T.Text
  , rErrors :: S.Seq ResolverError
  , funcType :: FunctionTypes
  , resolverEnv :: ResolverEnvironment
  , idenSequence :: S.Seq T.Text
  , newDeclarations :: Stack (S.Seq DECLARATION)
  , newExpressions :: Stack EXPRESSION
  , variableVector :: V.Vector EVAL
  , globalResolverTable :: GlobalResolverTable
  } deriving (Show)

createResolverMeta :: IO ResolverMeta
createResolverMeta = do
  resEnv <- createNewResEnv
  globTable <- createGlobalResolverTable
  return ResolverMeta {
    varIden=Nothing,
    rErrors=S.empty,
    funcType=NONE,
    resolverEnv=resEnv,
    idenSequence=S.empty,
    newDeclarations= push S.empty createStack,
    newExpressions=createStack,
    variableVector=V.empty,
    globalResolverTable=globTable
    }


addBlockToMeta :: ResolverMeta -> IO ResolverMeta
addBlockToMeta meta = do
  newEnv <- addNewBlockToResEnv (resolverEnv meta)
  return meta{resolverEnv=newEnv, newDeclarations=(push S.empty (newDeclarations meta))}

deleteBlockFromMeta :: ResolverMeta -> IO ResolverMeta
deleteBlockFromMeta meta = return meta{resolverEnv=(deleteBlockFromResEnv (resolverEnv meta))}

updateBlockInMeta :: ID -> T.Text -> ResolverMeta -> IO ResolverMeta
updateBlockInMeta id iden meta = do
  newEnv <- updateBlockInResEnv iden id (resolverEnv meta)
  return meta{resolverEnv=newEnv, varIden=Just iden}

updateBlockWithFunctionOrClassInMeta :: ID -> T.Text -> ResolverMeta -> IO ResolverMeta
updateBlockWithFunctionOrClassInMeta id iden meta = do
  newEnv <- updateBlockInResEnv iden id (resolverEnv meta)
  return meta{resolverEnv=newEnv}

findIdInVariables :: T.Text -> ResolverMeta ->IO (Maybe ID)
findIdInVariables iden meta
  | null resEnv = return Nothing
  | otherwise = do
    values <- mapM (getIdOfIden iden) resEnv
    let val = find isJust values
    if isJust val then return (fromJust val) else do
     maybeGlobId <- getGlobalVarId (globalResolverTable meta) iden 
     if isJust maybeGlobId then return maybeGlobId else return Nothing
  where resEnv = resolverEnv meta

findIdenInMeta :: T.Text -> ResolverMeta -> IO Bool
findIdenInMeta iden meta = isJust <$> findIdInVariables iden meta

checkIfResolverError :: ResolverMeta -> T.Text -> Bool
checkIfResolverError meta iden = Just iden == (varIden meta)

checkIfVarAlreadyAdded :: ResolverMeta -> T.Text -> IO Bool
checkIfVarAlreadyAdded meta iden = isJust <$> getIdOfIden iden currentBlock
  where currentBlock = peek resEnv
        resEnv = resolverEnv meta


cleanVarMeta :: ResolverMeta -> IO ResolverMeta
cleanVarMeta meta = return meta{varIden=Nothing}

addError :: ResolverError -> ResolverMeta -> IO ResolverMeta
addError error meta = return meta{rErrors=(rErrors meta S.|> error)}

updateFunctionType :: FunctionTypes -> ResolverMeta -> IO ResolverMeta
updateFunctionType fType meta = return meta{funcType=fType}


checkHandleIfAlreadyAdded :: (ResolverMeta -> T.Text -> IO ResolverMeta) -> S.Seq TH.Token -> T.Text -> ResolverMeta -> IO ResolverMeta
checkHandleIfAlreadyAdded f tokens iden meta  = do
   res <- checkIfVarAlreadyAdded meta iden
   if res then do
     addError (RESOLVER_ERROR "Variable already added in scope" tokens) meta
   else f meta iden

checkReturn :: (ResolverMeta -> IO ResolverMeta) -> ResolverMeta -> IO ResolverMeta
checkReturn f meta = if
    funcType meta == NONE
  then do
    addError (RESOLVER_ERROR "Cannot call return outside a function or a method" S.empty) meta
  else do f meta


addDecToMeta :: DECLARATION -> ResolverMeta -> IO ResolverMeta
addDecToMeta dec meta = do
  let (last, delDecs) = pop (newDeclarations meta)
  let lastNew = last S.|> dec
  return meta{newDeclarations=push lastNew delDecs}

addBlockDecToMeta :: ResolverMeta -> IO ResolverMeta
addBlockDecToMeta meta = do
  let (newBlockStmt, last, delDecs) = handleBlockStatementSave meta
  let lastUpdated = last S.|> DEC_STMT newBlockStmt
  return meta{newDeclarations= push lastUpdated delDecs}

addDecWithExprToMeta :: (EXPRESSION -> DECLARATION) -> ResolverMeta -> IO ResolverMeta
addDecWithExprToMeta unFinishedDec meta = addDecToMeta (unFinishedDec expr) newMeta
  where (expr, rest) = pop (newExpressions meta)
        newMeta = meta{newExpressions=rest}

addFunctionDecToMeta :: T.Text -> PARAMETERS -> ID -> FunctionTypes -> ResolverMeta -> IO ResolverMeta
addFunctionDecToMeta iden parameters id oldFuncType meta = do
   let (block, rest) = pop (newDeclarations meta)
   let (last, otherDecs) = pop rest
   let lastUpdated = last S.|> DEC_FUNC (FUNC_DEC (TH.IDENTIFIER iden) parameters (FUNC_STMT (BLOCK_STMT block)) id)
   return meta{newDeclarations=push lastUpdated otherDecs, funcType=oldFuncType}
   
addClassDecToMeta :: T.Text -> S.Seq DECLARATION -> Int -> ResolverMeta -> IO ResolverMeta
addClassDecToMeta iden methods id meta = do
   let (block, rest) = pop (newDeclarations meta)
   let (last, otherDecs) = pop rest
   let lastUpdated = last S.|> DEC_CLASS (CLASS_DEC (TH.IDENTIFIER iden) methods (LOCAL_ID id))
   return meta{newDeclarations=push lastUpdated otherDecs}

getLastDecFromMeta :: ResolverMeta -> IO (DECLARATION, ResolverMeta)
getLastDecFromMeta meta = do
  let newDecs = newDeclarations meta
  let (last, otherDecs) = pop newDecs
  let (rest, wrappedDec) = S.splitAt (S.length last-1) last
  return (S.index wrappedDec 0,meta{newDeclarations=push rest otherDecs})

addIfLoopDecToMeta :: (EXPRESSION -> STATEMENT -> DECLARATION) -> ResolverMeta -> IO ResolverMeta
addIfLoopDecToMeta unfinishedDec meta = do
  let (block, decRest) = pop (newDeclarations meta)
  let (last, delDecs) = pop decRest
  let (expr, rest) = pop (newExpressions meta)
  let lastUpdated = last S.|> unfinishedDec expr (BLOCK_STMT block)
  return meta{newDeclarations=push lastUpdated decRest, newExpressions=rest}


addIfElseDecToMeta :: (EXPRESSION -> STATEMENT -> STATEMENT -> DECLARATION) -> ResolverMeta -> IO ResolverMeta
addIfElseDecToMeta unfinishedDec meta = do
  let (secondBlock, firstDelDecs) = pop (newDeclarations meta)
  let (firstBlock, secondDelDecs) = pop firstDelDecs
  let last = peek secondDelDecs
  let (expr, rest) = pop (newExpressions meta)
  let lastUpdated = last S.|> unfinishedDec expr (BLOCK_STMT firstBlock) (BLOCK_STMT secondBlock)
  return meta{newDeclarations=push lastUpdated secondDelDecs, newExpressions=rest}


handleBlockStatementSave :: ResolverMeta -> (STATEMENT, S.Seq DECLARATION, Stack (S.Seq DECLARATION))
handleBlockStatementSave meta = (BLOCK_STMT currentBlockDecs, last, delDecs)
  where (currentBlockDecs, delDecs) = pop (newDeclarations meta)
        last = peek delDecs

addTernaryExpr :: (OPERATOR, OPERATOR, S.Seq TH.Token) -> ResolverMeta -> IO ResolverMeta
addTernaryExpr (op1, op2, tokens) meta = return meta{newExpressions=newExprs}
  where (thirdExpr, fRest) = pop (newExpressions meta)
        (secondExpr, sRest) = pop fRest
        (firstExpr, tRest) = pop sRest
        newExprs = push (EXP_TERNARY (TERN firstExpr op1 secondExpr op2 thirdExpr) tokens) tRest

addBinaryExpr :: (OPERATOR, S.Seq TH.Token) -> ResolverMeta -> IO ResolverMeta
addBinaryExpr (op, tokens) meta = return meta{newExpressions=newExprs}
  where (right, fRest) = pop (newExpressions meta)
        (left, sRest) = pop fRest
        newExprs = push (EXP_BINARY (_ left op right) tokens) sRest

addClosingExpr :: (EXPRESSION -> EXPRESSION) -> ResolverMeta -> IO ResolverMeta
addClosingExpr cexpr meta = return meta{newExpressions=newExprs}
  where (expr, rest) = pop (newExpressions meta)
        newExprs = push (cexpr expr) rest

addSimpleExpr :: EXPRESSION -> ResolverMeta -> IO ResolverMeta
addSimpleExpr expr meta = return meta{newExpressions=push expr (newExpressions meta)}

addVariableToVector :: T.Text -> Int -> ResolverMeta -> IO ResolverMeta
addVariableToVector iden id meta = do
  return meta{variableVector=(V.snoc (variableVector meta) EVAL_NIL)}

--TODO: print
printFunc :: ResolverMeta -> IO ResolverMeta
printFunc meta = do
  print (newDeclarations meta)
  return meta
-}