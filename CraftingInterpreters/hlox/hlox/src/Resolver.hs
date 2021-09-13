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


resolve ::  DECLARATION -> ResolverMeta -> IO ResolverMeta
resolve (DEC_STMT (BLOCK_STMT decs)) meta = incDepth meta >>= resolveMulti decs >>= decDepth

resolve (DEC_VAR (VAR_DEC_DEF (TH.IDENTIFIER iden) expr)) meta = checkHandleIfAlreadyAdded handleDecDef iden meta
  where handleDecDef meta iden = updateMapInMeta meta iden >>= resolveExpression expr >>= cleanVarMeta

resolve (DEC_VAR (VAR_DEC (TH.IDENTIFIER iden))) meta = checkHandleIfAlreadyAdded updateMapInMeta iden meta

resolve (DEC_VAR (VAR_DEF (TH.IDENTIFIER iden) expr tokens)) meta = return meta

resolve  (DEC_FUNC (FUNC_DEC (TH.IDENTIFIER iden) (PARAMETERS params) (FUNC_STMT (BLOCK_STMT decs)))) meta =
  incDepth meta >>= resolveParams (PARAMETERS params) >>= resolveMulti decs >>= decDepth

resolve (DEC_STMT (EXPR_STMT x)) meta = resolveExpression x meta

resolve (DEC_STMT (IF_STMT expr stmt)) meta = resolve (createDecFromStatement stmt) meta

resolve (DEC_STMT (IF_ELSE_STMT expr stmt1 stmt2)) meta = resolve (createDecFromStatement stmt1) meta >>= resolve (createDecFromStatement stmt2)
 
resolve (DEC_STMT (WHILE_STMT expr stmt)) meta = resolve (createDecFromStatement stmt) meta

resolve (DEC_STMT (FOR_STMT varDec expr incDec stmt)) meta = incDepth meta >>= resolve varDec >>= decDepth >>= resolve (createDecFromStatement stmt)

resolve (DEC_STMT (RETURN expr)) meta = do
  -- add functionality
  return meta

resolve _ meta  = return meta


-- TODO: handle multiple params with the same name
resolveParams :: PARAMETERS -> ResolverMeta -> IO ResolverMeta
resolveParams (PARAMETERS params) meta
  | S.null params = return meta
  | otherwise = checkHandleIfAlreadyAdded (callResolveParams params) paramName meta
  where param = S.index params 0
        (EXP_LITERAL (IDENTIFIER paramName b)) = param
        callResolveParams params meta paramName = updateMapInMeta meta paramName >>= cleanVarMeta >>= resolveParams (PARAMETERS (S.drop 1 params))


resolveExpressionMulti ::  S.Seq EXPRESSION -> ResolverMeta -> IO ResolverMeta
resolveExpressionMulti exprs meta
  | S.null exprs = return meta
  | otherwise = resolveExpression (S.index exprs 0) meta >>= resolveExpressionMulti (S.drop 1 exprs)


resolveExpression :: EXPRESSION ->  ResolverMeta -> IO ResolverMeta
resolveExpression (EXP_TERNARY (TERN expr1 op1 expr2 op2 expr3) _) meta = resolveExpression expr1 meta >>= resolveExpression expr2 >>= resolveExpression expr3
resolveExpression (EXP_BINARY (BIN left op right) bLines) meta = resolveExpression left meta >>= resolveExpression right
resolveExpression (EXP_CALL (CALL_FUNC expr arguments)) meta = resolveExpression expr meta
resolveExpression (EXP_GROUPING (GROUP x)) meta = resolveExpression x meta
resolveExpression (EXP_UNARY (UNARY op x) tokens) meta = resolveExpression x meta
resolveExpression (EXP_LITERAL (IDENTIFIER iden tokens)) meta = do
  res <- checkIfResolverError meta iden
  if res then do
    addError (RESOLVER_ERROR "Can't read local variable in its own initializer." tokens) meta
  else do
    return meta
resolveExpression _ meta = return meta

