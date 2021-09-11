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
  let scopes = createScope
  (_, newDepthMap) <- resolveDeclarations scopes depthMap x
  return newDepthMap

resolveDeclarations :: Stack ResolveMap -> DepthMap  -> S.Seq DECLARATION -> IO (Stack ResolveMap, DepthMap)
resolveDeclarations scopes depthMap decs
  | S.null decs = return (scopes, depthMap)
  | otherwise = do
      (newScopes, newDepthMap)  <- resolve scopes depthMap (S.index decs 0)
      resolveDeclarations newScopes newDepthMap (S.drop 1 decs)

declare :: Stack ResolveMap -> T.Text -> IO (ResolveMap, Stack ResolveMap)
declare scopes iden = do
    print (S.length scopes)
    let (scope,tailScopes) = popScope scopes
    newScope <- addUpdateToResolveMap scope iden False
    return (newScope, tailScopes)

define :: Stack ResolveMap -> ResolveMap -> T.Text -> IO (Stack ResolveMap)
define tailScopes addedToScope iden = do
    updatedScope <- addUpdateToResolveMap addedToScope iden True
    return (pushScope tailScopes updatedScope)

declareAndDefine :: Stack ResolveMap -> T.Text -> IO (Stack ResolveMap)
declareAndDefine scopes iden = do
    if S.null scopes then do return scopes else do
      (addedToScope, tailScopes) <- declare scopes iden
      define tailScopes addedToScope iden

resolveMulti :: Stack ResolveMap -> DepthMap -> S.Seq DECLARATION -> IO (Stack ResolveMap, DepthMap)
resolveMulti s dm decs
  | S.null decs = return (s, dm)
  | otherwise = do
      (newScopes, newDepthMap) <- resolve s dm dec
      resolveMulti newScopes newDepthMap (S.drop 1 decs)
  where dec = S.index decs 0


resolve :: Stack ResolveMap -> DepthMap -> DECLARATION -> IO (Stack ResolveMap, DepthMap)
resolve scopes depthMap (DEC_STMT (BLOCK_STMT decs)) = do
  rMap <- createResolveMap
  let startScopes = beginScope scopes rMap
  (resScopes, newDepthMap) <- resolveMulti startScopes depthMap decs
  let endScopes = endScope resScopes
  return (snd endScopes, newDepthMap)

resolve scopes depthMap (DEC_VAR (VAR_DEC_DEF (TH.IDENTIFIER iden) _)) = do
  if
    null scopes
  then do
   return (scopes, depthMap)
  else do
--declare
    (addedToScope, tailScopes) <- declare scopes iden
-- here resolve expr
-- TODO: Handle error in Either type
    maybeInResolveMap <- findInResolveMap iden addedToScope
    if maybeInResolveMap == Just False then do
      print "Can't read local variable in its own initializer."
      return (scopes, depthMap)
    else do
      (localResolved, newDepthMap) <- resolveLocal scopes depthMap iden 0
-- define
      newScopes <- define tailScopes addedToScope iden
      return (newScopes, newDepthMap)

resolve scopes depthMap (DEC_VAR (VAR_DEF (TH.IDENTIFIER iden) expr tokens)) = do
  exprScope <- resolveExpression scopes expr
  resolveLocal scopes depthMap iden 0

resolve scopes depthMap (DEC_FUNC (FUNC_DEC (TH.IDENTIFIER iden) (PARAMETERS params) (FUNC_STMT (BLOCK_STMT decs)))) = do
  updatedScope <- declareAndDefine scopes iden

  rMap <- createResolveMap
  let startScopes = beginScope updatedScope rMap
  paramUpdatedScopes <- resolveParams scopes (PARAMETERS params)
  (resScopes,newDepthMap)  <- resolveMulti startScopes depthMap decs
  let endScopes = endScope resScopes
  return (snd endScopes, newDepthMap)

resolve scopes depthMap (DEC_STMT (EXPR_STMT x)) = do
  newScopes <- resolveExpression scopes x
  return (newScopes, depthMap)

resolve scopes depthMap (DEC_STMT (IF_STMT expr stmt)) = do
  newScopes <- resolveExpression scopes expr
  resolve newScopes depthMap (createDecFromStatement stmt)

resolve scopes depthMap (DEC_STMT (IF_ELSE_STMT expr stmt1 stmt2)) = do
  firstScopes <- resolveExpression scopes expr
  (newScopes, newDepthMap) <- resolve firstScopes depthMap (createDecFromStatement stmt1)
  resolve newScopes newDepthMap (createDecFromStatement stmt2)

resolve scopes depthMap (DEC_STMT (RETURN expr)) = do
  newScopes <- resolveExpression scopes expr
  return (newScopes, depthMap)

resolve scopes depthMap _ = return (scopes, depthMap)

resolveLocal :: Stack ResolveMap -> DepthMap -> T.Text -> Int -> IO (Stack ResolveMap, DepthMap)
resolveLocal scopes depthMap iden depth
  | depth > S.length scopes-1 = return (scopes, depthMap)
  | otherwise = do
    let scopeToLook = S.index scopes depth
    maybeInResolveMap <- findInResolveMap iden scopeToLook
    if isJust maybeInResolveMap then do
      newDepthMap <- resolveDepth depthMap iden (depth+1)
      return (scopes, newDepthMap)
    else do
      resolveLocal scopes depthMap iden (depth+1)


resolveParams :: Stack ResolveMap -> PARAMETERS -> IO (Stack ResolveMap)
resolveParams scopes (PARAMETERS params)
  | S.null params = return scopes
  | otherwise = do
    let (EXP_LITERAL (IDENTIFIER paramName b)) = S.index params 0
    newScopes <- declareAndDefine scopes paramName
    resolveParams newScopes (PARAMETERS (S.drop 1 params))


resolveDepth :: DepthMap -> T.Text -> Int -> IO DepthMap
resolveDepth = addUpdateToDepthMap

resolveExpressionMulti :: Stack ResolveMap -> S.Seq EXPRESSION -> IO (Stack ResolveMap)
resolveExpressionMulti scopes exprs
  | S.null exprs = return scopes
  | otherwise = do
      newScopes <- resolveExpression scopes (S.index exprs 0)
      resolveExpressionMulti newScopes (S.drop 1 exprs)
resolveArguments :: Stack ResolveMap -> S.Seq ARGUMENTS -> IO (Stack ResolveMap)
resolveArguments scopes argumentlist
  | S.null argumentlist = return scopes
  | otherwise = do
      let (ARGS args) = S.index argumentlist 0
      newScopes <- resolveExpressionMulti scopes args
      resolveArguments newScopes (S.drop 1 argumentlist)


resolveExpression :: Stack ResolveMap -> EXPRESSION -> IO (Stack ResolveMap)
resolveExpression scopes (EXP_TERNARY (TERN expr1 op1 expr2 op2 expr3) _) = do
  firstScopes <-  resolveExpression scopes expr1
  secondScopes <- resolveExpression firstScopes expr2
  resolveExpression secondScopes expr3
resolveExpression scopes (EXP_BINARY (BIN left op right) bLines) = do
  newScopes <- resolveExpression scopes left
  resolveExpression newScopes right
resolveExpression scopes  (EXP_CALL (CALL_FUNC expr arguments)) = do
  newScopes <- resolveExpression scopes expr
  resolveArguments newScopes arguments
resolveExpression scopes (EXP_GROUPING (GROUP x)) = resolveExpression scopes x
resolveExpression scopes (EXP_UNARY (UNARY op x) tokens) = resolveExpression scopes x
resolveExpression scopes (EXP_LITERAL _) = return scopes
