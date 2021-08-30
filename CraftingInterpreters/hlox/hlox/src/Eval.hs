{-# LANGUAGE OverloadedStrings #-}

module Eval where

import AST
import qualified Data.Text as T
import Data.Maybe
import qualified Data.Sequence as S
import qualified TokenHelper as TH
import EvalTypes
import Environment
import NativeFunctions

-- TODO: Break and continue, if we have time

evalProgram :: PROGRAM -> IO ()
evalProgram (PROG x) = do
  eval x SKIP_EVAL createGlobalEnvironment False
  return ()



evalBlock :: S.Seq DECLARATION -> Environments -> IO (IO EVAL, IO Environments)
evalBlock x env = do
  (pIO, envIO) <- eval x SKIP_EVAL (createLocalEnvironment env) False
  let newEnvIO = deleteLocalEnvironment <$> envIO
  return (pIO, newEnvIO)



eval :: S.Seq DECLARATION -> EVAL -> IO Environments -> Bool  -> IO (IO EVAL, IO Environments)
eval decs prev env shouldCheckReturn = do
  if S.null decs then do
    if shouldCheckReturn
      then do return (return (RETURN_EVAL EVAL_NIL), env)
      else do return (return prev, env)
  else do
    (ev, newEnv) <- evalDeclaration (S.index decs 0) env
    if shouldCheckReturn && isReturn ev
      then do return(return ev, env)
      else do
       if isRuntimeError ev
         then do
           print ev
           return (return ev, env)
          else do
            eval (S.drop 1 decs) ev (return newEnv) shouldCheckReturn



evalDeclaration :: DECLARATION -> IO Environments -> IO (EVAL, Environments)
evalDeclaration (DEC_STMT (PRINT_STMT x)) env = do
  locEnv <- env
  (expr, newEnv) <- evalExpression x locEnv
  print expr
  return (expr, locEnv)
evalDeclaration (DEC_STMT (EXPR_STMT x)) env = do
  locEnv <- env
  evalExpression x locEnv
evalDeclaration (DEC_VAR (VAR_DEC_DEF (TH.IDENTIFIER iden) expr)) env = do
  locEnv <- env
  (locExpr, newEnv) <- evalExpression expr locEnv
  handleVarDeclarationAndDefinition iden locExpr newEnv
evalDeclaration (DEC_VAR (VAR_DEC (TH.IDENTIFIER iden))) env = do
  locEnv <- env
  handleVarDeclaration iden locEnv
evalDeclaration (DEC_VAR (VAR_DEF (TH.IDENTIFIER iden) expr tokens)) env = do
  locEnv <- env
  (locExpr, newEnv) <- evalExpression expr locEnv
  handleVarDefinition iden locExpr newEnv tokens
evalDeclaration (DEC_STMT (BLOCK_STMT x)) env = do
  locEnv <- env
  (evIO, newEnvIO) <- evalBlock x locEnv
  newEnv <- newEnvIO
  ev <- evIO
  return (ev, newEnv)
evalDeclaration (DEC_STMT (IF_STMT expr stmt)) env = do
  locEnv <- env
  (exprVal, newEnv) <- evalExpression expr locEnv
  if maybeEvalTruthy exprVal == Just True then evalDeclaration (createDecFromStatement stmt) (return newEnv) else return (SKIP_EVAL, newEnv)
evalDeclaration (DEC_STMT (IF_ELSE_STMT expr stmt1 stmt2)) env = do
  locEnv <- env
  (exprVal,newEnv)  <- evalExpression expr locEnv
  if
    maybeEvalTruthy exprVal == Just True
  then evalDeclaration (createDecFromStatement stmt1) (return newEnv)
  else evalDeclaration (createDecFromStatement stmt2) (return newEnv)

evalDeclaration (DEC_STMT (WHILE_STMT expr stmt)) env = do
  evalDeclaration (DEC_STMT (LOOP expr SKIP_DEC stmt)) env

evalDeclaration (DEC_STMT (FOR_STMT varDec expr incDec stmt)) env = do
  nonIOEnv <- env
  let locEnvIO =  createLocalEnvironment nonIOEnv
  (ev, decEnv) <- evalDeclaration varDec locEnvIO
  if isRuntimeError ev then do
    return (ev, nonIOEnv)
  else do
    (checkEval, checkEnv) <- evalExpression expr decEnv
    if isRuntimeError checkEval then do return (checkEval, checkEnv) else do
      (newEv, newEnv) <- evalDeclaration (createDecFromStatement stmt) (return decEnv)
      if isRuntimeError newEv then do return (newEv, newEnv) else do
        evalDeclaration (DEC_STMT (LOOP expr incDec stmt)) (return newEnv)

evalDeclaration (DEC_STMT (LOOP expr dec stmt)) env = do
  firstEnv <- env
  (ev, secondEnv) <- if (not . isSkipDec) dec then evalDeclaration dec (return firstEnv) else return (SKIP_EVAL, firstEnv)
  if isRuntimeError ev then do return (ev, secondEnv) else do
    (checkEval, checkEnv) <- evalExpression expr secondEnv
    if isRuntimeError checkEval then do return (checkEval, checkEnv) else do
      if maybeEvalTruthy checkEval == Just True then do
        (newEv, newEnv) <- evalDeclaration (createDecFromStatement stmt) (return secondEnv)
        if isRuntimeError newEv then do return (newEv, newEnv) else do
          evalDeclaration (DEC_STMT (LOOP expr dec stmt)) (return newEnv)
      else return (SKIP_EVAL, secondEnv)

evalDeclaration (DEC_FUNC (FUNC_DEC (TH.IDENTIFIER iden) (PARAMETERS params) stmt)) env = do
  locEnv <- env
  let eval = FUNC_DEC_EVAL iden (S.length params) (PARAMETERS params) stmt
  newEnv <- addIdentifierToEnvironment iden eval locEnv
  return (eval, newEnv)

evalDeclaration (DEC_STMT (RETURN expr)) env = do
  locEnv <- env
  (ev, newEnv) <- evalExpression expr locEnv
  return (ev, newEnv)

evalDeclaration (DEC_STMT RETURN_NIL) env = do
  locEnv <- env
  return (EVAL_NIL, locEnv)

evalDeclaration x env = do
  locEnv <- env
  print x
  return (RUNTIME_ERROR "Unknown error occured" S.empty, locEnv)


-- Think about redefinement
handleVarDeclaration :: TextType -> Environments -> IO (EVAL, Environments)
handleVarDeclaration iden env = do
  newEnv <- addIdentifierToEnvironment iden EVAL_NIL env
  return (DEC_EVAL iden EVAL_NIL, newEnv)

handleVarDeclarationAndDefinition :: TextType -> EVAL -> Environments -> IO (EVAL, Environments)
handleVarDeclarationAndDefinition iden val env = do
  newEnv <- addIdentifierToEnvironment iden val env
  return (DEC_EVAL iden val, newEnv)

handleVarDefinition :: TextType -> EVAL -> Environments -> S.Seq TH.Token -> IO (EVAL, Environments)
handleVarDefinition iden val env tokens = do
  (newEnv, isSuccess) <- updateIdentifierToEnvironment iden val env
  if isSuccess then return (DEC_EVAL iden val, newEnv) else return (RUNTIME_ERROR "Identifier is not defined" tokens, env)





evalExpression :: EXPRESSION -> Environments -> IO (EVAL, Environments)
evalExpression (EXP_LITERAL (NUMBER x)) env = return (EVAL_NUMBER x, env)
evalExpression (EXP_LITERAL (STRING x)) env = return (EVAL_STRING x, env)
evalExpression (EXP_LITERAL FALSE) env = return (EVAL_BOOL False, env)
evalExpression (EXP_LITERAL TRUE) env = return (EVAL_BOOL True, env)
evalExpression (EXP_LITERAL NIL) env = return (EVAL_NIL, env)
evalExpression (EXP_LITERAL (IDENTIFIER x tokens)) env = do
  val <- findValueOfIdentifier x env
  if isJust val then return (fromJust val, env) else return (RUNTIME_ERROR "Identifier is not defined" tokens, env)

evalExpression (EXP_GROUPING (GROUP x)) env = evalExpression x env

evalExpression (EXP_UNARY (UNARY op x) tokens) env = do
  (expr, newEnv) <- evalExpression x env
  return (evalUnary tokens op expr, newEnv)

evalExpression (EXP_BINARY (BIN left op right) bLines) env = do
  (evaledLeft, leftEnv) <- evalExpression left env
  (evaledRight, rightEnv) <- evalExpression right leftEnv
  return (evalBinary bLines evaledLeft op evaledRight, rightEnv)

evalExpression (EXP_TERNARY (TERN predi _ trueRes _ falseRes) tLines) env = do
  (evalPred, newEnv) <- evalExpression predi env
  let evalTrueVal = evalTernary tLines evalPred trueRes falseRes
  evalTrueVal newEnv

evalExpression (EXP_CALL (CALL_FUNC exp args)) env = do
  (eval, newEnv) <- evalExpression exp env
  evalFunctions newEnv eval args

evalExpression _ env = return (RUNTIME_ERROR "Expression cannot be evaluated" (S.fromList []), env)





evalUnary :: S.Seq TH.Token -> OPERATOR -> EVAL -> EVAL
evalUnary tokens op expr
  | op == AST.MINUS && isJust valNum = EVAL_NUMBER (-(fromJust valNum))
  | op == AST.BANG && isJust valTruthy = EVAL_BOOL (not (fromJust valTruthy))
  | otherwise = RUNTIME_ERROR "Operand must be a number" tokens
  where valNum = maybeEvalNumber expr
        valTruthy = maybeEvalTruthy expr


evalFunctions :: Environments -> EVAL -> S.Seq ARGUMENTS -> IO (EVAL, Environments)
evalFunctions env (FUNC_DEC_EVAL iden arity params stmt) argCalls
  | S.null argCalls = return (FUNC_DEC_EVAL iden arity params stmt, env)
  | otherwise = do
      (eval, newEnv) <- callFunction env (FUNC_DEC_EVAL iden arity params stmt) (S.index argCalls 0) 
      evalFunctions newEnv eval (S.drop 1 argCalls)
  where args = S.index argCalls 0
evalFunctions env ev _ = return (ev, env)


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


evalTernary :: S.Seq TH.Token -> EVAL -> EXPRESSION -> EXPRESSION -> (Environments -> IO(EVAL, Environments))
evalTernary tokens predi trueRes falseRes
  | preppedPred == Just True = evalExpression trueRes
  | preppedPred == Just False = evalExpression falseRes
  | otherwise = buildRuntimeError
  where preppedPred = maybeEvalTruthy predi
        buildRuntimeError env = return (RUNTIME_ERROR "Ternary operator failed" tokens, env)

-- Helpers
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



callFunction :: Environments -> EVAL -> ARGUMENTS ->IO (EVAL, Environments)
callFunction env (FUNC_DEC_EVAL iden arity params stmt) (ARGS args)
  | S.length args /= arity = return (RUNTIME_ERROR (T.pack (mconcat ["Expected ", show arity, " arguments", ", but got ", show argsLength])) S.empty, env)
  | otherwise = functionCall env iden params (ARGS args) stmt
  where argsLength = S.length args


functionCall :: Environments -> AST.TextType -> PARAMETERS -> ARGUMENTS -> FUNCTION_STATEMENT -> IO (EVAL, Environments)
functionCall env iden params args (FUNC_STMT (BLOCK_STMT decs)) = do
  locEnv <- createLocalEnvironment env
  let savedEnv = saveFunctionArgs locEnv params args
  (pIO, locEnvIO) <- eval decs SKIP_EVAL savedEnv True
  locEnv <- locEnvIO
  let newEnv = deleteLocalEnvironment locEnv
  returnEval <- pIO
  let evalValue = getValueFromReturn returnEval
  return (evalValue, newEnv)
functionCall env iden params args (NATIVE_FUNC_STMT f) = do
  eval <- callNativeFunction f args
  return (eval, env)


saveFunctionArgs :: Environments -> PARAMETERS -> ARGUMENTS -> IO Environments
saveFunctionArgs env (PARAMETERS params) (ARGS args)
 | S.null params = return env
 | otherwise = do
     let (EXP_LITERAL (IDENTIFIER p b)) = S.index params 0
     let a = S.index args 0
     (evalA, evalEnv) <- evalExpression a env
     newEnv <- addIdentifierToEnvironment p evalA evalEnv
     saveFunctionArgs newEnv (PARAMETERS (S.drop 1 params)) (ARGS (S.drop 1 args))

callNativeFunction :: NATIVE_FUNCTION_TYPES -> ARGUMENTS -> IO EVAL
callNativeFunction (CLOCK x) params = do
  val <- (x id)
  return (EVAL_NUMBER (fromInteger val))

