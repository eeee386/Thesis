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
resolveProgram (PROG x) = createResolverMeta >>= resolveMulti x

resolveMulti ::  S.Seq DECLARATION -> ResolverMeta -> IO ResolverMeta
resolveMulti decs meta
  | S.null decs = return meta
  | otherwise =  resolve dec meta >>= resolveMulti (S.drop 1 decs)
  where dec = S.index decs 0


resolve :: DECLARATION -> ResolverMeta -> IO ResolverMeta
resolve (DEC_STMT (BLOCK_STMT decs)) meta = addBlockToMeta meta >>= resolveMulti decs >>= addBlockDecToMeta >>= deleteBlockFromMeta

resolve (DEC_VAR (VAR_DEC_DEF (TH.IDENTIFIER iden) expr tokens (LOCAL_ID id))) meta = checkHandleIfAlreadyAdded handleDecDef tokens iden meta
  where handleDecDef meta iden = updateBlockInMeta (LOCAL_ID id) iden meta >>= resolveExpression expr >>= cleanVarMeta >>= addVariableToVector iden id >>= addDecWithExprToMeta (\x -> DEC_VAR (VAR_DEC_DEF (TH.IDENTIFIER iden) x tokens (LOCAL_ID id)))

resolve (DEC_VAR (VAR_DEC (TH.IDENTIFIER iden) tokens (LOCAL_ID id))) meta = checkHandleIfAlreadyAdded handleDec tokens iden meta
  where handleDec meta iden = updateBlockInMeta (LOCAL_ID id) iden meta >>= cleanVarMeta >>= addVariableToVector iden id >>= addDecToMeta (DEC_VAR (VAR_DEC (TH.IDENTIFIER iden) tokens (LOCAL_ID id)))

resolve (DEC_VAR (VAR_DEF (TH.IDENTIFIER iden) expr tokens NOT_READY)) meta = do
  maybeId <- findIdInVariables iden meta
  if isNothing maybeId then do
    addError (RESOLVER_ERROR "Variable is not defined" tokens) meta
  else resolveExpression expr meta >>= addDecWithExprToMeta (\x -> DEC_VAR (VAR_DEF (TH.IDENTIFIER iden) x tokens (fromJust maybeId)))

-- TODO: Add tokens to function declaration in AST!
resolve  (DEC_FUNC (FUNC_DEC (TH.IDENTIFIER iden) parameters (FUNC_STMT (BLOCK_STMT decs)) (LOCAL_ID id))) meta = checkHandleIfAlreadyAdded handleFunction S.empty iden meta 
  where oldFuncType = funcType meta
        handleFunction meta iden = updateBlockWithFunctionOrClassInMeta (LOCAL_ID id) iden meta >>= printFunc >>= addVariableToVector iden id >>= updateFunctionType FUNCTION >>= addBlockToMeta >>= resolveParams parameters >>= resolveMulti decs >>= addFunctionDecToMeta iden parameters (LOCAL_ID id) oldFuncType

resolve  (DEC_FUNC (FUNC_DEC (TH.IDENTIFIER iden) parameters (FUNC_STMT (BLOCK_STMT decs)) Utils.METHOD)) meta = checkHandleIfAlreadyAdded handleFunction S.empty iden meta 
  where oldFuncType = funcType meta
        handleFunction meta iden = updateBlockWithFunctionOrClassInMeta Utils.METHOD iden meta >>= printFunc >>= updateFunctionType ResolverTypes.METHOD >>= addBlockToMeta >>= resolveParams parameters >>= resolveMulti decs >>= addFunctionDecToMeta iden parameters Utils.METHOD oldFuncType

-- TODO: Add tokens to class declaration in AST!
resolve (DEC_CLASS (CLASS_DEC (TH.IDENTIFIER iden) methods (LOCAL_ID id))) meta = checkHandleIfAlreadyAdded handleClass S.empty iden meta
  where handleClass meta iden = updateBlockWithFunctionOrClassInMeta (LOCAL_ID id) iden meta >>= addVariableToVector iden id >>= addBlockToMeta >>= resolveMulti methods >>= addClassDecToMeta iden methods id

resolve (DEC_STMT (EXPR_STMT x)) meta = resolveExpression x meta >>= addDecWithExprToMeta (DEC_STMT . EXPR_STMT)

resolve (DEC_STMT (IF_STMT expr (BLOCK_STMT decs))) meta = resolveIfWhile (\x y -> DEC_STMT (IF_STMT x (BLOCK_STMT y))) expr decs meta

resolve (DEC_STMT (IF_ELSE_STMT expr (BLOCK_STMT decs1) (BLOCK_STMT decs2))) meta = resolveIfElse expr decs1 decs2 meta

resolve (DEC_STMT (WHILE_STMT expr (BLOCK_STMT decs))) meta = resolveIfWhile (\x block -> DEC_STMT (WHILE_STMT x (BLOCK_STMT block))) expr decs meta

resolve (DEC_STMT (FOR_STMT varDec expr incDec (BLOCK_STMT decs))) meta = resolveForLoop varDec expr incDec decs meta

--TODO: Add Tokens to returns in the AST!
resolve (DEC_STMT (RETURN expr)) meta = checkReturn (handleReturn expr) meta
  where handleReturn expr meta = resolveExpression expr meta >>= addDecWithExprToMeta (DEC_STMT . RETURN)

resolve (DEC_STMT RETURN_NIL) meta = checkReturn return meta

resolve (DEC_STMT (PRINT_STMT x)) meta = resolveExpression x meta >>= addDecWithExprToMeta (DEC_STMT . PRINT_STMT)

resolve dec meta = addDecToMeta dec meta

resolveBlockStatement :: S.Seq DECLARATION -> ResolverMeta -> IO ResolverMeta
resolveBlockStatement decs meta = addBlockToMeta meta >>= resolveMulti decs 

resolveForLoop  :: DECLARATION -> EXPRESSION -> DECLARATION -> S.Seq DECLARATION -> ResolverMeta -> IO ResolverMeta
resolveForLoop varDec expr incDec decs meta = do
  varMeta <- resolve varDec meta
  (nVar, lastMeta) <- getLastDecFromMeta varMeta
  exprMeta <- resolveExpression expr lastMeta
  let (x, xRest) = pop (newExpressions exprMeta)
  incMeta <- resolve incDec exprMeta{newExpressions=xRest}
  (nInc, incLastMeta) <- getLastDecFromMeta incMeta
  blockMeta <- resolveBlockStatement decs incLastMeta
  let (block, blockRest) = pop (newDeclarations blockMeta)
  addDecToMeta (DEC_STMT (FOR_STMT nVar x nInc (BLOCK_STMT block))) blockMeta{newDeclarations=blockRest}

--TODO: Why did not work from monads I wonder...
resolveIfWhile :: (EXPRESSION -> S.Seq DECLARATION -> DECLARATION) -> EXPRESSION -> S.Seq DECLARATION -> ResolverMeta -> IO ResolverMeta
resolveIfWhile unfinishedDec expr decs meta  = do
  exprMeta  <- resolveExpression expr meta
  let (x, xRest) = pop (newExpressions exprMeta)
  blockMeta <- resolveBlockStatement decs exprMeta{newExpressions=xRest}
  let (block, blockRest) = pop (newDeclarations blockMeta)
  addDecToMeta (unfinishedDec x block) meta{newDeclarations=blockRest}

resolveIfElse :: EXPRESSION -> S.Seq DECLARATION -> S.Seq DECLARATION -> ResolverMeta -> IO ResolverMeta
resolveIfElse expr decs1 decs2 meta = do
  exprMeta  <- resolveExpression expr meta
  let (x, xRest) = pop (newExpressions exprMeta)
  blockMeta1 <- resolveBlockStatement decs1 exprMeta{newExpressions=xRest}
  let (block1, blockRest1) = pop (newDeclarations blockMeta1)
  blockMeta2 <- resolveBlockStatement decs2 blockMeta1{newDeclarations=blockRest1}
  let (block2, blockRest2) = pop (newDeclarations blockMeta2)
  addDecToMeta (DEC_STMT (IF_ELSE_STMT x (BLOCK_STMT block1) (BLOCK_STMT block2))) meta{newDeclarations=blockRest2}

resolveParams :: PARAMETERS -> ResolverMeta -> IO ResolverMeta
resolveParams (PARAMETERS params tokens) meta
  | S.null params = return meta
  | otherwise = checkHandleIfAlreadyAdded (callResolveParams params) tokens iden meta
  where param = S.index params 0
        (DEC_VAR (PARAM_DEC (TH.IDENTIFIER iden) tokens pid)) = param
        callResolveParams params meta iden = updateBlockInMeta pid iden meta >>= cleanVarMeta >>= resolveParams (PARAMETERS (S.drop 1 params) tokens)


-- ResolveExpression
resolveExpressionMulti ::  S.Seq EXPRESSION -> ResolverMeta -> IO ResolverMeta
resolveExpressionMulti exprs meta
  | S.null exprs = return meta
  | otherwise = resolveExpression (S.index exprs 0) meta >>= resolveExpressionMulti (S.drop 1 exprs)

resolveArgs :: S.Seq ARGUMENTS -> S.Seq ARGUMENTS  -> ResolverMeta -> IO (S.Seq ARGUMENTS, ResolverMeta)
resolveArgs args newArgs meta
  | S.null args = return (newArgs, meta)
  | otherwise = do
    exprsMeta <- resolveExpressionMulti exprs meta
    let newExprs = newExpressions exprsMeta
    resolveArgs (S.drop 1 args) (newArgs S.|> ARGS (S.fromList (take (S.length exprs) newExprs))) meta{newExpressions=drop (S.length exprs) newExprs}
  where (ARGS exprs) = S.index args 0


addCallExpression :: EXPRESSION -> S.Seq ARGUMENTS -> ID ->  ResolverMeta -> IO ResolverMeta
addCallExpression expr args id meta = do
  exprMeta <- resolveExpression expr meta
  let (x, _) = pop (newExpressions exprMeta)
  (newArgs, newMeta) <- resolveArgs args S.empty exprMeta
  addSimpleExpr (EXP_CALL (CALL_FUNC x newArgs id)) newMeta


resolveExpression :: EXPRESSION ->  ResolverMeta -> IO ResolverMeta
resolveExpression (EXP_TERNARY (TERN expr1 op1 expr2 op2 expr3) tokens) meta =
  resolveExpression expr1 meta >>= resolveExpression expr2 >>= resolveExpression expr3 >>= addTernaryExpr (op1, op2, tokens)
resolveExpression (EXP_BINARY (BIN left op right) tokens) meta = resolveExpression left meta >>= resolveExpression right >>= addBinaryExpr (op, tokens)
resolveExpression (EXP_CALL (CALL_FUNC expr arguments id)) meta = addCallExpression expr arguments id meta
resolveExpression (EXP_GROUPING (GROUP x)) meta = resolveExpression x meta >>= addClosingExpr (EXP_GROUPING . GROUP)
resolveExpression (EXP_UNARY (UNARY op x) tokens) meta = resolveExpression x meta >>= addClosingExpr (\ex -> EXP_UNARY (UNARY op ex) tokens)
resolveExpression (EXP_LITERAL (IDENTIFIER iden tokens id)) meta = do
  if checkIfResolverError meta iden then do
    addError (RESOLVER_ERROR "Can't read local variable in its own initializer." tokens) meta
  else do
    maybeId <- findIdInVariables iden meta
    if isNothing maybeId then do
      addError (RESOLVER_ERROR "Variable is not declared yet." tokens) meta
    else do
      addSimpleExpr (EXP_LITERAL (IDENTIFIER iden tokens (fromJust maybeId))) meta

resolveExpression expr meta = addSimpleExpr expr meta

