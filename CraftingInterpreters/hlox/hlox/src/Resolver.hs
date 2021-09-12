module Resolver where


import ResolverTypes
import Utils
import qualified Data.Sequence as S
import AST
import qualified  Data.Text as T
import qualified TokenHelper as TH
import Data.Maybe

resolveProgram :: PROGRAM -> IO ResolverMeta
resolveProgram (PROG x) = do
  meta <- createResolverMeta
  newDepthMap <- resolveDeclarations meta x
  return newDepthMap

resolveDeclarations :: ResolverMeta -> S.Seq DECLARATION -> IO ResolverMeta
resolveDeclarations meta decs
  | S.null decs = return meta
  | otherwise = do
      newMeta <- resolve meta (S.index decs 0)
      resolveDeclarations newMeta (S.drop 1 decs)

resolveMulti :: ResolverMeta -> S.Seq DECLARATION -> IO ResolverMeta
resolveMulti meta decs
  | S.null decs = return meta
  | otherwise = do
      newMeta <- resolve meta dec
      resolveMulti newMeta (S.drop 1 decs)
  where dec = S.index decs 0


resolve :: ResolverMeta -> DECLARATION -> IO ResolverMeta
resolve meta (DEC_STMT (BLOCK_STMT decs)) = do
  newMeta <- resolveMulti meta decs
  return newMeta

resolve meta (DEC_VAR (VAR_DEC_DEF (TH.IDENTIFIER iden) expr)) = do
   newMeta  <-updateMapInMeta meta iden
   resolveExpression newMeta expr
   return newMeta

resolve meta (DEC_VAR (VAR_DEC (TH.IDENTIFIER iden))) = updateMapInMeta meta iden

resolve meta (DEC_VAR (VAR_DEF (TH.IDENTIFIER iden) expr tokens)) = return meta

resolve meta (DEC_FUNC (FUNC_DEC (TH.IDENTIFIER iden) (PARAMETERS params) (FUNC_STMT (BLOCK_STMT decs)))) = do
  paramUpdatedScopes <- resolveParams meta (PARAMETERS params)
  newMeta <- resolveMulti (incDepth meta) decs
  return newMeta

resolve meta (DEC_STMT (EXPR_STMT x)) = do
  resolveExpression meta x
  return meta

resolve meta (DEC_STMT (IF_STMT expr stmt)) = do
  resolve meta (createDecFromStatement stmt)

resolve meta (DEC_STMT (IF_ELSE_STMT expr stmt1 stmt2)) = do
  newMeta <- resolve meta (createDecFromStatement stmt1)
  resolve newMeta (createDecFromStatement stmt2)

resolve meta (DEC_STMT (WHILE_STMT expr stmt)) = do
  resolve meta (createDecFromStatement stmt)

resolve meta (DEC_STMT (FOR_STMT varDec expr incDec stmt)) = do
  let metaToUse = incDepth meta
  varDepthMap <- resolve metaToUse varDec
  resolve metaToUse (createDecFromStatement stmt)


resolve meta (DEC_STMT (RETURN expr)) = do
  -- add functionality
  return meta

resolve depthMap _  = return depthMap

resolveParams :: ResolverMeta -> PARAMETERS -> IO ResolverMeta
resolveParams meta (PARAMETERS params)
  | S.null params = return meta
  | otherwise = do
    let param = S.index params 0
    let (EXP_LITERAL (IDENTIFIER paramName b)) = param
    newMeta <- updateMapInMeta (incDepth meta) paramName
    resolveExpression newMeta param
    resolveParams newMeta (PARAMETERS (S.drop 1 params))


resolveExpressionMulti :: ResolverMeta -> S.Seq EXPRESSION -> IO ()
resolveExpressionMulti meta exprs
  | S.null exprs = return ()
  | otherwise = do
      resolveExpression meta (S.index exprs 0)
      resolveExpressionMulti meta (S.drop 1 exprs)


resolveExpression :: ResolverMeta ->  EXPRESSION -> IO ()
resolveExpression meta (EXP_TERNARY (TERN expr1 op1 expr2 op2 expr3) _) = do
  resolveExpression meta expr1
  resolveExpression meta expr2
  resolveExpression meta expr3
resolveExpression meta (EXP_BINARY (BIN left op right) bLines) = do
  resolveExpression meta left
  resolveExpression meta right
resolveExpression meta (EXP_CALL (CALL_FUNC expr arguments)) = do
  resolveExpression meta expr
resolveExpression meta (EXP_GROUPING (GROUP x)) = resolveExpression meta x
resolveExpression meta (EXP_UNARY (UNARY op x) tokens) = resolveExpression meta x
resolveExpression meta (EXP_LITERAL (IDENTIFIER iden tokens))= do
  print "this is called"
  print meta
  res <- checkIfResolverError meta iden
  if res then do
    print "Can't read local variable in its own initializer."
  else do
    return ()

resolveExpression _ _ = return ()
