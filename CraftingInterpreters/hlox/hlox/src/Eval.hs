{-# LANGUAGE OverloadedStrings #-}

module Eval where

import AST
import qualified Data.Text as T
import Data.Maybe
import qualified Data.Sequence as S
import qualified TokenHelper as TH
import EvalTypes
import NativeFunctions
import ResolverTypes
import qualified Data.Vector as V
import EvalMeta
import NativeFunctionTypes

-- TODO: Break and continue, if we have time

evalProgram :: PROGRAM -> V.Vector EVAL -> IO ()
evalProgram (PROG x) vector = do
  eval x SKIP_EVAL (createGlobalMeta vector)
  return ()



evalBlock :: S.Seq DECLARATION -> META -> IO (IO EVAL, IO META)
evalBlock x meta = eval x SKIP_EVAL (return meta)


eval :: S.Seq DECLARATION -> EVAL -> IO META -> IO (IO EVAL, IO META)
eval decs prev meta = do
  nonIOMeta <- meta
  if S.null decs then do
    return (return prev, meta)
  else do
    (ev, newMeta) <- evalDeclaration (S.index decs 0) meta
    if isInFunction newMeta && isReturn ev
      then do return(return ev, meta)
      else do
       if isRuntimeError ev
         then do
           return (return ev, meta)
          else do
            eval (S.drop 1 decs) ev (return newMeta)


-- Evaluate Declaration
evalDeclaration :: DECLARATION -> IO META -> IO (EVAL, META)
evalDeclaration (DEC_STMT (PRINT_STMT x)) meta = do
  locMeta <- meta
  (expr, newMeta) <- evalExpression x locMeta
  print expr
  return (expr, locMeta)
evalDeclaration (DEC_STMT (EXPR_STMT x)) meta = do
  locMeta <- meta
  evalExpression x locMeta
evalDeclaration (DEC_VAR (VAR_DEC_DEF (TH.IDENTIFIER iden) expr tokens id)) meta = do
  locMeta <- meta
  (locExpr, newMeta) <- evalExpression expr locMeta
  handleVarDeclarationAndDefinition iden id locExpr newMeta
evalDeclaration (DEC_VAR (VAR_DEC (TH.IDENTIFIER iden) tokens id)) meta = do
  locMeta <- meta
  handleVarDeclaration iden id locMeta
evalDeclaration (DEC_VAR (VAR_DEF (TH.IDENTIFIER iden) expr tokens id)) meta = do
  locMeta <- meta
  (locExpr, newMeta) <- evalExpression expr locMeta
  handleVarDefinition iden id locExpr newMeta tokens
evalDeclaration (DEC_STMT (BLOCK_STMT x)) meta = do
  locMeta <- meta
  (evIO, newMetaIO) <- evalBlock x locMeta
  newMeta <- newMetaIO
  ev <- evIO
  return (ev, newMeta)
evalDeclaration (DEC_STMT (IF_STMT expr stmt)) meta = do
  locMeta <- meta
  (exprVal, newMeta) <- evalExpression expr locMeta
  if maybeEvalTruthy exprVal == Just True then evalDeclaration (createDecFromStatement stmt) (return newMeta) else return (SKIP_EVAL, newMeta)
evalDeclaration (DEC_STMT (IF_ELSE_STMT expr stmt1 stmt2)) meta = do
  locMeta <- meta
  (exprVal,newMeta)  <- evalExpression expr locMeta
  if
    maybeEvalTruthy exprVal == Just True
  then evalDeclaration (createDecFromStatement stmt1) (return newMeta)
  else evalDeclaration (createDecFromStatement stmt2) (return newMeta)

evalDeclaration (DEC_STMT (WHILE_STMT expr stmt)) meta = do
  evalDeclaration (DEC_STMT (LOOP expr SKIP_DEC stmt)) meta

evalDeclaration (DEC_STMT (FOR_STMT varDec expr incDec stmt)) meta = do
  (ev, decMeta) <- evalDeclaration varDec meta
  if isRuntimeError ev then do
    return (ev, decMeta)
  else do
    (checkEval, checkMeta) <- evalExpression expr decMeta
    if isRuntimeError checkEval then do return (checkEval, checkMeta) else do
      (newEv, newMeta) <- evalDeclaration (createDecFromStatement stmt) (return decMeta{isInLoop=True})
      if returnFromLoop newEv newMeta  then do return (newEv, newMeta) else do
        evalDeclaration (DEC_STMT (LOOP expr incDec stmt)) (return newMeta)

evalDeclaration (DEC_STMT (LOOP expr dec stmt)) meta = do
  firstMeta <- meta
  (ev, secondMeta) <- if (not . isSkipDec) dec then evalDeclaration dec (return firstMeta) else return (SKIP_EVAL, firstMeta)
  if isRuntimeError ev then do return (ev, secondMeta) else do
    (checkEval, checkMeta) <- evalExpression expr secondMeta
    if isRuntimeError checkEval then do return (checkEval, checkMeta) else do
      if maybeEvalTruthy checkEval == Just True then do
        (newEv, newMeta) <- evalDeclaration (createDecFromStatement stmt) (return secondMeta{isInLoop=True})
        if returnFromLoop newEv newMeta then do return (newEv, newMeta) else do
          evalDeclaration (DEC_STMT (LOOP expr dec stmt)) (return newMeta{isInLoop=False})
      else return (SKIP_EVAL, secondMeta)

evalDeclaration (DEC_FUNC (FUNC_DEC (TH.IDENTIFIER iden) (PARAMETERS params tokens) stmt id)) meta = do
  locMeta <- meta
  let eval = FUNC_DEC_EVAL iden (S.length params) (PARAMETERS params tokens) stmt
  newMeta <- addUpdateValueToMeta id eval locMeta
  return (eval, newMeta)

evalDeclaration (DEC_STMT (RETURN expr)) meta = do
  locMeta <- meta
  (ev, newMeta) <- evalExpression expr locMeta
  return (RETURN_EVAL ev, newMeta)

evalDeclaration (DEC_STMT RETURN_NIL) meta = do
  locMeta <- meta
  return (EVAL_NIL, locMeta)

evalDeclaration x meta = do
  locMeta <- meta
  print x
  return (RUNTIME_ERROR "Unknown error occured" S.empty, locMeta)

-- Evaluate variable declaration and/or definition
-- Think about redefinement
handleVarDeclaration :: T.Text  -> ID -> META -> IO (EVAL, META)
handleVarDeclaration iden id meta = do
  newMeta <- addUpdateValueToMeta id EVAL_NIL meta
  return (DEC_EVAL iden EVAL_NIL id, newMeta)

handleVarDeclarationAndDefinition :: TextType -> ID -> EVAL -> META -> IO (EVAL, META)
handleVarDeclarationAndDefinition iden id val meta = do
  newMeta <- addUpdateValueToMeta id val meta
  return (DEC_EVAL iden val id, newMeta)

handleVarDefinition :: TextType -> ID -> EVAL -> META -> S.Seq TH.Token -> IO (EVAL, META)
handleVarDefinition iden id val meta tokens = do
  newMeta <- addUpdateValueToMeta id val meta
  return (DEC_EVAL iden val id, newMeta)




-- Evaluate expression
evalExpression :: EXPRESSION -> META -> IO (EVAL, META)
evalExpression (EXP_LITERAL (NUMBER x)) meta = return (EVAL_NUMBER x, meta)
evalExpression (EXP_LITERAL (STRING x)) meta = return (EVAL_STRING x, meta)
evalExpression (EXP_LITERAL FALSE) meta = return (EVAL_BOOL False, meta)
evalExpression (EXP_LITERAL TRUE) meta = return (EVAL_BOOL True, meta)
evalExpression (EXP_LITERAL NIL) meta = return (EVAL_NIL, meta)
evalExpression (EXP_LITERAL (IDENTIFIER iden tokens id)) meta = do
  if isInFunction meta 
  then do
    val <- findValueInFunction iden id meta
    return (val, meta)
  else do
    val <- findValueInMeta id meta
    return (val, meta)

evalExpression (EXP_GROUPING (GROUP x)) meta = evalExpression x meta

evalExpression (EXP_UNARY (UNARY op x) tokens) meta = do
  (expr, newMeta) <- evalExpression x meta
  return (evalUnary tokens op expr, newMeta)

evalExpression (EXP_BINARY (BIN left op right) bLines) meta = do
  (evaledLeft, leftMeta) <- evalExpression left meta
  (evaledRight, rightMeta) <- evalExpression right leftMeta
  return (evalBinary bLines evaledLeft op evaledRight, rightMeta)

evalExpression (EXP_TERNARY (TERN predi _ trueRes _ falseRes) tLines) meta = do
  (evalPred, newMeta) <- evalExpression predi meta
  let evalTrueVal = evalTernary tLines evalPred trueRes falseRes
  evalTrueVal newMeta

evalExpression (EXP_CALL (CALL_FUNC exp args id)) meta = do
  (eval, newMeta) <- evalExpression exp meta
  evalFunctions newMeta eval args

evalExpression _ meta = return (RUNTIME_ERROR "Expression cannot be evaluated" (S.fromList []), meta)


-- evalExpression helpers
evalUnary :: S.Seq TH.Token -> OPERATOR -> EVAL -> EVAL
evalUnary tokens op expr
  | op == AST.MINUS && isJust valNum = EVAL_NUMBER (-(fromJust valNum))
  | op == AST.BANG && isJust valTruthy = EVAL_BOOL (not (fromJust valTruthy))
  | otherwise = RUNTIME_ERROR "Operand must be a number" tokens
  where valNum = maybeEvalNumber expr
        valTruthy = maybeEvalTruthy expr


evalFunctions :: META -> EVAL -> S.Seq ARGUMENTS -> IO (EVAL, META)
evalFunctions meta (FUNC_DEC_EVAL iden arity params stmt) argCalls
  | S.null argCalls = return (FUNC_DEC_EVAL iden arity params stmt, meta)
  | otherwise = do
      (eval, newMeta) <- callFunction meta (FUNC_DEC_EVAL iden arity params stmt) (S.index argCalls 0)
      evalFunctions newMeta eval (S.drop 1 argCalls)
  where args = S.index argCalls 0
evalFunctions meta ev _ = return (ev, meta)


evalBinary :: S.Seq TH.Token -> EVAL -> OPERATOR -> EVAL -> EVAL
evalBinary tokens evalLeft op evalRight
 | op == MINUS = getArithOp (-)
 | op == SLASH = getArithOp (/)
 | op == STAR = getArithOp (*)
 | op == PLUS = handlePlus
 | op == GREATER = getCompOp (>)
 | op == GREATER_EQUAL = getCompOp (>=)
 | op == LESS = getCompOp (<)
 | op == LESS_EQUAL = getCompOp (<=)
 | op == EQUAL_EQUAL = equals
 | op == BANG_EQUAL = notEquals
 | op == AND = createAnd evalLeft evalRight
 | op == OR = createOr evalLeft evalRight
 where leftNum = maybeEvalNumber evalLeft
       rightNum = maybeEvalNumber evalRight
       leftStr = maybeEvalString evalLeft
       rightStr = maybeEvalString evalRight
       getArithOp = createArithmeticOps tokens leftNum rightNum
       getCompOp = createComparison tokens leftNum rightNum
       equals = createEquality evalLeft evalRight id
       notEquals = createEquality evalLeft evalRight not
       handlePlus
         | isJust leftNum && isJust rightNum = getArithOp (+)
         | isJust leftStr && isJust rightStr = concatTwoString (fromJust leftStr) (fromJust rightStr)
         | otherwise = RUNTIME_ERROR "Operands must be two numbers or two strings" tokens


evalTernary :: S.Seq TH.Token -> EVAL -> EXPRESSION -> EXPRESSION -> (META -> IO(EVAL, META))
evalTernary tokens predi trueRes falseRes
  | preppedPred == Just True = evalExpression trueRes
  | preppedPred == Just False = evalExpression falseRes
  | otherwise = buildRuntimeError
  where preppedPred = maybeEvalTruthy predi
        buildRuntimeError meta = return (RUNTIME_ERROR "Ternary operator failed" tokens, meta)

-- Helpers for operations
maybeEvalNumber :: EVAL -> Maybe Double
maybeEvalNumber (EVAL_NUMBER x) = Just x
maybeEvalNumber _ = Nothing

maybeEvalTruthy :: EVAL -> Maybe Bool
maybeEvalTruthy (EVAL_BOOL False) = Just False
maybeEvalTruthy (EVAL_BOOL True) = Just True
maybeEvalTruthy (EVAL_NUMBER _) = Just True
maybeEvalTruthy (EVAL_STRING _) = Just True
maybeEvalTruthy _ = Nothing

maybeEvalString :: EVAL -> Maybe AST.TextType
maybeEvalString (EVAL_STRING x) = Just x
maybeEvalString _ = Nothing

concatTwoString :: AST.TextType -> AST.TextType -> EVAL
concatTwoString l r = EVAL_STRING (T.concat [l,r])

createMathOp :: (a -> EVAL) -> S.Seq TH.Token -> Maybe Double -> Maybe Double -> (Double -> Double -> a)  -> EVAL
createMathOp x tokens l r f = if isJust l && isJust r then x (f (fromJust l) (fromJust r)) else RUNTIME_ERROR "Operands must be numbers" tokens

createArithmeticOps :: S.Seq TH.Token -> Maybe Double -> Maybe Double -> (Double -> Double -> Double) -> EVAL
createArithmeticOps = createMathOp EVAL_NUMBER

createComparison :: S.Seq TH.Token -> Maybe Double -> Maybe Double -> (Double -> Double -> Bool) -> EVAL
createComparison = createMathOp EVAL_BOOL

createOr :: EVAL -> EVAL -> EVAL
createOr l r = if maybeEvalTruthy l == Just True then l else r

createAnd :: EVAL -> EVAL -> EVAL
createAnd l r = if maybeEvalTruthy l == Just False then l else r

createEquality :: (Eq a) => a -> a -> (Bool -> Bool) -> EVAL
createEquality l r ch = if l == r then EVAL_BOOL (ch True) else EVAL_BOOL (ch False)


-- Helpers for functions
callFunction :: META -> EVAL -> ARGUMENTS ->IO (EVAL, META)
callFunction meta (FUNC_DEC_EVAL iden arity params stmt) (ARGS args)
  | S.length args /= arity = return (RUNTIME_ERROR (T.pack (mconcat ["Expected ", show arity, " arguments", ", but got ", show argsLength])) S.empty, meta)
  | otherwise = functionCall meta (FUNC_DEC_EVAL iden arity params stmt) (ARGS args)
  where argsLength = S.length args

-- TODO: right now all of them saves to one variable, is is fine for blocks and loops, but for functions when there are multiple one running 
-- It should be different closure for all function call, so params should be taken out of the resolver, and functions should build up their closures
functionCall :: META -> EVAL -> ARGUMENTS -> IO (EVAL, META)
functionCall meta (FUNC_DEC_EVAL iden _ params (FUNC_STMT (BLOCK_STMT decs))) arguments = do
  toEvalMeta <- addNewScopeToMeta meta >>= saveFunctionArgs params arguments
  (pIO, afterMetaIO) <- eval decs SKIP_EVAL (return toEvalMeta{isInFunction=True, isInLoop=False})
  afterMeta <- afterMetaIO
  returnEval <- pIO
  let evalValue = getValueFromReturn returnEval
  return (evalValue, afterMeta{isInFunction=isInFunction meta, isInLoop=isInLoop meta, closure=deleteScopeFromClosure (closure meta)})
functionCall meta (FUNC_DEC_EVAL iden _ params (NATIVE_FUNC_STMT f)) arguments = do
  eval <- callNativeFunction f arguments
  return (eval, meta)


saveFunctionArgs :: PARAMETERS -> ARGUMENTS -> META -> IO META
saveFunctionArgs (PARAMETERS params tokens) (ARGS args) meta
 | S.null params = return meta
 | otherwise = do
     let (DEC_VAR (PARAM_DEC (TH.IDENTIFIER iden) tokens _)) = S.index params 0
     let a = S.index args 0
     (evalA, evalMeta) <- evalExpression a meta
     newMeta <- addUpdateScopeInMeta iden evalA evalMeta
     saveFunctionArgs (PARAMETERS (S.drop 1 params) tokens) (ARGS (S.drop 1 args)) newMeta

callNativeFunction :: NATIVE_FUNCTION_TYPES -> ARGUMENTS -> IO EVAL
callNativeFunction (CLOCK x) _ = do
  val <- x id
  return (EVAL_NUMBER (fromInteger val))

returnFromLoop :: EVAL -> META -> Bool
returnFromLoop newEv newMeta = isRuntimeError newEv || (isInFunction newMeta && isReturn newEv)
