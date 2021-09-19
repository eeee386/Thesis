{-# LANGUAGE OverloadedStrings #-}

module ResolverTypes where

import qualified Data.HashTable.IO as HT
import Utils
import qualified Data.Text as T
import qualified Data.Sequence as S
import AST
import qualified TokenHelper as TH
import Data.Maybe

-- ResolverError
data ResolverError = RESOLVER_ERROR T.Text (S.Seq TH.Token) deriving Show

-- Function Types
data FunctionTypes = NONE | FUNCTION | METHOD deriving (Show, Eq)

-- Resolver Environment
type ResolverBlockEnvironment = HT.BasicHashTable T.Text Int

type ResolverEnvironment = S.Seq ResolverBlockEnvironment

createResolverBlockEnvironment :: IO ResolverBlockEnvironment
createResolverBlockEnvironment = HT.new

addNewBlockToResEnv :: ResolverEnvironment -> IO ResolverEnvironment
addNewBlockToResEnv resEnv = do
  block <- createResolverBlockEnvironment
  return (resEnv S.|> block)

createNewResEnv ::  IO ResolverEnvironment
createNewResEnv = addNewBlockToResEnv S.empty

deleteBlockFromResEnv :: ResolverEnvironment -> ResolverEnvironment
deleteBlockFromResEnv resEnv = S.take (S.length resEnv-1) resEnv

updateBlockInResEnv :: T.Text -> Int ->  ResolverEnvironment -> IO ResolverEnvironment
updateBlockInResEnv iden id resEnv  = do
  let last = S.index resEnv (S.length resEnv-1)
  HT.insert last iden id
  let delResEnv = deleteBlockFromResEnv resEnv
  return (delResEnv S.|> last)

getIdOfIden :: T.Text -> ResolverBlockEnvironment -> IO (Maybe Int)
getIdOfIden iden resEnv = HT.lookup resEnv iden

findIdInResolverEnv :: T.Text -> ResolverEnvironment ->IO (Maybe Int)
findIdInResolverEnv iden resEnv
  | S.null resEnv = return Nothing
  | otherwise = do
    values <- mapM (getIdOfIden iden) resEnv
    let index = S.findIndexR isJust values
    if isJust index then return (S.index values (fromJust index)) else return Nothing


-- ResolverMeta
data ResolverMeta = ResolverMeta {
   varIden :: Maybe T.Text
  , rErrors :: S.Seq ResolverError
  , funcType :: FunctionTypes
  , resolverEnv :: ResolverEnvironment
  , idenSequence :: S.Seq T.Text
  , newDeclarations :: Stack (S.Seq DECLARATION)
  , newExpressions :: Stack EXPRESSION
  } deriving (Show)

createResolverMeta :: IO ResolverMeta
createResolverMeta = do
  resEnv <- createNewResEnv
  return ResolverMeta {varIden=Nothing, rErrors=S.empty, funcType=NONE, resolverEnv=resEnv, idenSequence=S.empty, newDeclarations=createStack}


addBlockToMeta :: ResolverMeta -> IO ResolverMeta
addBlockToMeta meta = do
  newEnv <- addNewBlockToResEnv (resolverEnv meta)
  return meta{resolverEnv=newEnv, newDeclarations=(push S.empty (newDeclarations meta))}

deleteBlockFromMeta :: ResolverMeta -> IO ResolverMeta
deleteBlockFromMeta meta = return meta{resolverEnv=(deleteBlockFromResEnv (resolverEnv meta))}

updateBlockInMeta ::Int -> T.Text -> ResolverMeta -> IO ResolverMeta
updateBlockInMeta id iden meta = do
  newEnv <- updateBlockInResEnv iden id (resolverEnv meta)
  return meta{resolverEnv=newEnv, varIden=Just iden}

findIdenInMeta :: T.Text -> ResolverMeta -> IO Bool
findIdenInMeta iden meta = isJust <$> findIdInResolverEnv iden (resolverEnv meta)

checkIfResolverError :: ResolverMeta -> T.Text -> Bool
checkIfResolverError meta iden = Just iden /= (varIden meta)

checkIfVarAlreadyAdded :: ResolverMeta -> T.Text -> IO Bool
checkIfVarAlreadyAdded meta iden = isJust <$> getIdOfIden iden currentBlock
  where currentBlock = (S.index resEnv (S.length resEnv-1))
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

addFunctionDecToMeta ::T.Text -> PARAMETERS -> Int -> ResolverMeta -> IO ResolverMeta
addFunctionDecToMeta iden parameters id meta = do 
  let (newBlockStmt, last, delDecs) = handleBlockStatementSave meta
  let lastUpdated = last S.|> DEC_FUNC (FUNC_DEC (TH.IDENTIFIER iden) parameters (FUNC_STMT newBlockStmt) (Id id))
  return meta{newDeclarations=push lastUpdated delDecs}


handleBlockStatementSave :: ResolverMeta -> (STATEMENT, S.Seq DECLARATION, Stack (S.Seq DECLARATION))
handleBlockStatementSave meta = (BLOCK_STMT currentBlockDecs, last, delDecs)
  where (currentBlockDecs, delDecs) = pop (newDeclarations meta)
        last = peek delDecs

addTernaryExpr :: (OPERATOR, OPERATOR, S.Seq TH.Token) -> ResolverMeta -> IO ResolverMeta
addTernaryExpr (op1, op2, tokens) meta = return meta{newExpressions=newExprs}
  where (firstExpr, fRest) = pop (newExpressions meta)
        (secondExpr, sRest) = pop fRest
        (thirdExpr, tRest) = pop sRest
        newExprs = push (EXP_TERNARY (TERN firstExpr op1 secondExpr op2 thirdExpr) tokens) tRest

addBinaryExpr :: (OPERATOR, S.Seq TH.Token) -> ResolverMeta -> IO ResolverMeta
addBinaryExpr (op, tokens) meta = return meta{newExpressions=newExprs}
  where (left, fRest) = pop (newExpressions meta)
        (right, sRest) = pop fRest
        newExprs = push (EXP_BINARY (BIN left op right) tokens) sRest

addClosingExpr :: (EXPRESSION -> EXPRESSION) -> ResolverMeta -> IO ResolverMeta
addClosingExpr cexpr meta = return meta{newExpressions=newExprs}
  where (expr, rest) = pop (newExpressions meta)
        newExprs = push (cexpr expr) rest

addSimpleExpr :: EXPRESSION -> ResolverMeta -> IO ResolverMeta
addSimpleExpr expr meta = return meta{newExpressions=push expr (newExpressions meta)}
