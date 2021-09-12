module Resolver where


import ResolverTypes
import Utils
import qualified Data.Sequence as S
import AST
import qualified  Data.Text as T
import qualified TokenHelper as TH
import Data.Maybe

resolveProgram :: PROGRAM -> IO DepthMap
resolveProgram (PROG x) = do
  depthMap <- createDepthMap
  newDepthMap <- resolveDeclarations depthMap 0 x
  return newDepthMap

resolveDeclarations :: DepthMap -> Int -> S.Seq DECLARATION -> IO DepthMap
resolveDeclarations depthMap depth decs
  | S.null decs = return depthMap
  | otherwise = do
      newDepthMap <- resolve depthMap depth (S.index decs 0)
      resolveDeclarations newDepthMap depth (S.drop 1 decs)

resolveMulti :: DepthMap -> Int -> S.Seq DECLARATION -> IO DepthMap
resolveMulti dm depth decs
  | S.null decs = return dm
  | otherwise = do
      newDepthMap <- resolve dm depth dec
      resolveMulti newDepthMap depth (S.drop 1 decs)
  where dec = S.index decs 0


resolve :: DepthMap -> Int -> DECLARATION -> IO DepthMap
resolve depthMap depth (DEC_STMT (BLOCK_STMT decs)) = do
  newDepthMap <- resolveMulti depthMap (depth+1) decs
  return newDepthMap

resolve depthMap depth (DEC_VAR (VAR_DEC_DEF (TH.IDENTIFIER iden) expr)) = do
   resolveExpression depthMap expr
   addUpdateToDepthMap depthMap iden depth

resolve depthMap depth (DEC_VAR (VAR_DEC (TH.IDENTIFIER iden))) = do
   addUpdateToDepthMap depthMap iden depth

resolve depthMap depth (DEC_VAR (VAR_DEF (TH.IDENTIFIER iden) expr tokens)) = return depthMap

resolve depthMap depth (DEC_FUNC (FUNC_DEC (TH.IDENTIFIER iden) (PARAMETERS params) (FUNC_STMT (BLOCK_STMT decs)))) = do
  paramUpdatedScopes <- resolveParams depthMap depth (PARAMETERS params)
  newDepthMap <- resolveMulti depthMap (depth+1) decs
  return newDepthMap

resolve depthMap depth (DEC_STMT (EXPR_STMT x)) = do
  resolveExpression depthMap x
  return depthMap

resolve depthMap depth (DEC_STMT (PRINT_STMT x)) = do
  resolveExpression depthMap x
  return depthMap

resolve depthMap depth (DEC_STMT (IF_STMT expr stmt)) = do
  resolveExpression depthMap expr
  resolve depthMap depth (createDecFromStatement stmt)

resolve depthMap depth (DEC_STMT (IF_ELSE_STMT expr stmt1 stmt2)) = do
  resolveExpression depthMap expr
  newDepthMap <- resolve depthMap depth (createDecFromStatement stmt1)
  resolve newDepthMap depth (createDecFromStatement stmt2)

resolve depthMap depth (DEC_STMT (WHILE_STMT expr stmt)) = do
  resolveExpression depthMap expr
  resolve depthMap depth (createDecFromStatement stmt)

resolve depthMap depth (DEC_STMT (FOR_STMT varDec expr incDec stmt)) = do
  let depthToUse = depth+1
  varDepthMap <- resolve depthMap depthToUse varDec
  resolveExpression depthMap expr
  incDepthMap <- resolve varDepthMap depthToUse incDec
  resolve depthMap depthToUse (createDecFromStatement stmt)


resolve depthMap depth (DEC_STMT (RETURN expr)) = do
  resolveExpression depthMap expr
  return depthMap

resolve depthMap _ _  = return depthMap

resolveParams :: DepthMap -> Int  -> PARAMETERS -> IO DepthMap
resolveParams depthMap depth (PARAMETERS params)
  | S.null params = return depthMap
  | otherwise = do
    let (EXP_LITERAL (IDENTIFIER paramName b)) = S.index params 0
    newDepthMap  <- addUpdateToDepthMap depthMap paramName (depth+1)
    resolveParams newDepthMap depth (PARAMETERS (S.drop 1 params))


resolveExpressionMulti :: DepthMap -> S.Seq EXPRESSION -> IO ()
resolveExpressionMulti depthMap exprs
  | S.null exprs = return ()
  | otherwise = do
      newScopes <- resolveExpression depthMap (S.index exprs 0)
      resolveExpressionMulti depthMap (S.drop 1 exprs)
resolveArguments :: DepthMap -> S.Seq ARGUMENTS -> IO ()
resolveArguments depthMap argumentlist
  | S.null argumentlist = return ()
  | otherwise = do
      let (ARGS args) = S.index argumentlist 0
      print args
      resolveExpressionMulti depthMap args
      resolveArguments depthMap (S.drop 1 argumentlist)


resolveExpression :: DepthMap ->  EXPRESSION -> IO ()
resolveExpression depthMap (EXP_TERNARY (TERN expr1 op1 expr2 op2 expr3) _) = do
  resolveExpression depthMap expr1
  resolveExpression depthMap expr2
  resolveExpression depthMap expr3
resolveExpression depthMap (EXP_BINARY (BIN left op right) bLines) = do
  resolveExpression depthMap left
  resolveExpression depthMap right
resolveExpression depthMap (EXP_CALL (CALL_FUNC expr arguments)) = do
  resolveExpression depthMap expr
  resolveArguments depthMap arguments
resolveExpression depthMap (EXP_GROUPING (GROUP x)) = resolveExpression depthMap x
resolveExpression depthMap (EXP_UNARY (UNARY op x) tokens) = resolveExpression depthMap x
resolveExpression depthMap (EXP_LITERAL (IDENTIFIER iden tokens))= do
  print "Can't read local variable in its own initializer."
resolveExpression scopes _ = return ()
