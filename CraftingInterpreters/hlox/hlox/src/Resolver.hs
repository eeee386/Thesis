{-# LANGUAGE OverloadedStrings #-}

module Resolver where


import ResolverTypes
import Utils
import qualified Data.Sequence as S
import AST
import qualified  Data.Text as T
import qualified TokenHelper as TH
import Data.Maybe


resolveProgram :: PROGRAM -> IO ResolverMeta
resolveProgram (PROG x) = createResolverMeta >>= resolveDeclarations x

resolveDeclarations ::  S.Seq DECLARATION ->  ResolverMeta -> IO ResolverMeta
resolveDeclarations decs meta
  | S.null decs = return meta
  | otherwise = resolve (S.index decs 0) meta >>= resolveDeclarations (S.drop 1 decs)

resolveMulti ::  S.Seq DECLARATION -> ResolverMeta -> IO ResolverMeta
resolveMulti decs meta
  | S.null decs = return meta
  | otherwise =  resolve dec meta >>= resolveMulti (S.drop 1 decs)
  where dec = S.index decs 0


resolve :: DECLARATION -> ResolverMeta -> IO ResolverMeta
resolve (DEC_STMT (BLOCK_STMT decs)) meta = addBlockToMeta meta >>= resolveMulti decs >>= addBlockDecToMeta >>= deleteBlockFromMeta

resolve (DEC_VAR (VAR_DEC_DEF (TH.IDENTIFIER iden) expr tokens (Id id))) meta = checkHandleIfAlreadyAdded handleDecDef tokens iden meta
  where handleDecDef meta iden = updateBlockInMeta id iden meta >>= resolveExpression expr >>= cleanVarMeta >>= addDecToMeta (DEC_VAR (VAR_DEC_DEF (TH.IDENTIFIER iden) expr tokens (Id id)))

resolve (DEC_VAR (VAR_DEC (TH.IDENTIFIER iden) tokens (Id id))) meta = checkHandleIfAlreadyAdded handleDec tokens iden meta
  where handleDec meta iden = updateBlockInMeta id iden meta >>= addDecToMeta (DEC_VAR (VAR_DEC (TH.IDENTIFIER iden) tokens (Id id)))

resolve (DEC_VAR (VAR_DEF (TH.IDENTIFIER iden) expr tokens NOT_READY)) meta = do
  maybeId <- findIdInResolverEnv iden (resolverEnv meta)
  if isNothing maybeId then do
    addError (RESOLVER_ERROR "Variable is not defined" tokens) meta
  else do
    addDecToMeta (DEC_VAR (VAR_DEF (TH.IDENTIFIER iden) expr tokens (Id (fromJust maybeId)))) meta

resolve  (DEC_FUNC (FUNC_DEC (TH.IDENTIFIER iden) parameters (FUNC_STMT (BLOCK_STMT decs)) (Id id))) meta =
  updateBlockInMeta id iden meta >>= addBlockToMeta >>= updateFunctionType FUNCTION >>= resolveParams parameters >>= resolveMulti decs >>= updateFunctionType oldFuncType >>=  addFunctionDecToMeta iden parameters id >>= deleteBlockFromMeta
  where oldFuncType = funcType meta

resolve (DEC_STMT (EXPR_STMT x)) meta = resolveExpression x meta >>= addDecToMeta (DEC_STMT (EXPR_STMT x))

resolve (DEC_STMT (IF_STMT expr stmt)) meta = resolveExpression expr meta >>= resolve (createDecFromStatement stmt) >>= addDecToMeta (DEC_STMT (IF_STMT expr stmt))

resolve (DEC_STMT (IF_ELSE_STMT expr stmt1 stmt2)) meta = resolve (createDecFromStatement stmt1) meta >>= resolve (createDecFromStatement stmt2) >>= addDecToMeta (DEC_STMT (IF_ELSE_STMT expr stmt1 stmt2))

resolve (DEC_STMT (WHILE_STMT expr stmt)) meta = resolveExpression expr meta >>= resolve (createDecFromStatement stmt) >>= addDecToMeta (DEC_STMT (WHILE_STMT expr stmt))

resolve (DEC_STMT (FOR_STMT varDec expr incDec stmt)) meta = resolve varDec meta >>= resolveExpression expr >>= resolve incDec >>= resolve (createDecFromStatement stmt)
--TODO: Add Tokens to returns in the AST!
resolve (DEC_STMT (RETURN expr)) meta = checkReturn (resolveExpression expr) meta
  where handleReturn expr meta = resolveExpression expr meta >>= addDecToMeta (DEC_STMT (RETURN expr))

resolve (DEC_STMT RETURN_NIL) meta = checkReturn return meta

resolve (DEC_STMT (PRINT_STMT x)) meta = resolveExpression x meta >>= addDecToMeta (DEC_STMT (PRINT_STMT x))

resolve _ meta  = return meta


resolveParams :: PARAMETERS -> ResolverMeta -> IO ResolverMeta
resolveParams (PARAMETERS params tokens) meta
  | S.null params = return meta
  | otherwise = checkHandleIfAlreadyAdded (callResolveParams params) tokens iden meta
  where param = S.index params 0
        (DEC_VAR (PARAM_DEC (TH.IDENTIFIER iden) tokens (Id id))) = param
        callResolveParams params meta iden = updateBlockInMeta id iden meta >>= cleanVarMeta >>= resolveParams (PARAMETERS (S.drop 1 params) tokens)


-- ResolveExpression
resolveExpressionMulti ::  S.Seq EXPRESSION -> ResolverMeta -> IO ResolverMeta
resolveExpressionMulti exprs meta
  | S.null exprs = return meta
  | otherwise = resolveExpression (S.index exprs 0) meta >>= resolveExpressionMulti (S.drop 1 exprs)


resolveExpression :: EXPRESSION ->  ResolverMeta -> IO ResolverMeta
resolveExpression (EXP_TERNARY (TERN expr1 op1 expr2 op2 expr3) tokens) meta =
  resolveExpression expr1 meta >>= resolveExpression expr2 >>= resolveExpression expr3 >>= addTernaryExpr (op1, op2, tokens)
resolveExpression (EXP_BINARY (BIN left op right) tokens) meta = resolveExpression left meta >>= resolveExpression right >>= addBinaryExpr (op, tokens)
resolveExpression (EXP_CALL (CALL_FUNC expr arguments id)) meta =resolveExpression expr meta >>= addClosingExpr (\x -> EXP_CALL (CALL_FUNC x arguments id))
resolveExpression (EXP_GROUPING (GROUP x)) meta = resolveExpression x meta >>= addClosingExpr (EXP_GROUPING . GROUP)
resolveExpression (EXP_UNARY (UNARY op x) tokens) meta = resolveExpression x meta >>= addClosingExpr (\x -> EXP_UNARY (UNARY op x) tokens)
resolveExpression (EXP_LITERAL (IDENTIFIER iden tokens id)) meta = do
  if checkIfResolverError meta iden then do
    addError (RESOLVER_ERROR "Can't read local variable in its own initializer." tokens) meta
  else do
    maybeId <- findIdInResolverEnv iden (resolverEnv meta)
    if isNothing maybeId then do
      addError (RESOLVER_ERROR "Variable is not declared yet." tokens) meta
    else do
      addSimpleExpr (EXP_LITERAL (IDENTIFIER iden tokens (Id (fromJust maybeId)))) meta

resolveExpression expr meta = addSimpleExpr expr meta

