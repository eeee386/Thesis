{-# LANGUAGE OverloadedStrings #-}

module Resolver where


import ResolverTypes
import Utils
import qualified Data.Sequence as S
import AST
import qualified  Data.Text as T
import qualified TokenHelper as TH
import Data.Maybe

-- Create a sequence of sequence (add the index value in the block (which will be an id) in the parser so that both resolver and eval could read it, and an index value for vars in the block)
-- In Eval functions should save the environment (closure)
-- And eval will look up the block by its id, and the value by its index

-- This throws an error this should be fixed:  {var a = 5;}{var a = 4;}
-- Another bug:  var a = 5; {var a = 4;} print a;

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

resolve (DEC_VAR (VAR_DEC_DEF (TH.IDENTIFIER iden) expr tokens id)) meta = checkHandleIfAlreadyAdded handleDecDef tokens iden meta
  where handleDecDef meta iden = updateMapInMeta meta iden >>= resolveExpression expr >>= cleanVarMeta

resolve (DEC_VAR (VAR_DEC (TH.IDENTIFIER iden) tokens id)) meta = checkHandleIfAlreadyAdded updateMapInMeta tokens iden meta

resolve (DEC_VAR (VAR_DEF (TH.IDENTIFIER iden) expr tokens id)) meta = return meta

resolve  (DEC_FUNC (FUNC_DEC (TH.IDENTIFIER iden) parameters (FUNC_STMT (BLOCK_STMT decs)))) meta =
  updateMapInMeta meta iden >>= incDepth >>= updateFunctionType FUNCTION >>= resolveParams parameters >>= resolveMulti decs >>= updateFunctionType oldFuncType  >>= decDepth
  where oldFuncType = funcType meta

resolve (DEC_STMT (EXPR_STMT x)) meta = resolveExpression x meta

resolve (DEC_STMT (IF_STMT expr stmt)) meta = resolve (createDecFromStatement stmt) meta

resolve (DEC_STMT (IF_ELSE_STMT expr stmt1 stmt2)) meta = resolve (createDecFromStatement stmt1) meta >>= resolve (createDecFromStatement stmt2)
 
resolve (DEC_STMT (WHILE_STMT expr stmt)) meta = resolve (createDecFromStatement stmt) meta

resolve (DEC_STMT (FOR_STMT varDec expr incDec stmt)) meta = incDepth meta >>= resolve varDec >>= decDepth >>= resolve (createDecFromStatement stmt)
--TODO: Add Tokens!
resolve (DEC_STMT (RETURN expr)) meta = do
  if
    funcType meta == NONE
  then do
    addError (RESOLVER_ERROR "Cannot call return outside a function or a method" S.empty) meta
  else do return meta

resolve _ meta  = return meta


resolveParams :: PARAMETERS -> ResolverMeta -> IO ResolverMeta
resolveParams (PARAMETERS params tokens) meta
  | S.null params = return meta
  | otherwise = checkHandleIfAlreadyAdded (callResolveParams params) tokens paramName meta
  where param = S.index params 0
        (EXP_LITERAL (IDENTIFIER paramName b id)) = param
        callResolveParams params meta paramName = updateMapInMeta meta paramName >>= cleanVarMeta >>= resolveParams (PARAMETERS (S.drop 1 params) tokens)


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
resolveExpression (EXP_LITERAL (IDENTIFIER iden tokens id)) meta = do
  res <- checkIfResolverError meta iden
  if res then do
    addError (RESOLVER_ERROR "Can't read local variable in its own initializer." tokens) meta
  else do
    return meta
resolveExpression _ meta = return meta

