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
  eval x SKIP_EVAL createGlobalMeta
  return ()



evalBlock :: S.Seq DECLARATION -> META -> IO (IO EVAL, IO META)
evalBlock x meta = do
  (pIO, envIO) <- eval x SKIP_EVAL (updateMetaWithLocalEnv meta)
  let newEnvIO = deleteLocalEnvFromMeta <$> envIO
  return (pIO, newEnvIO)



eval :: S.Seq DECLARATION -> EVAL -> IO META -> IO (IO EVAL, IO META)
eval decs prev meta = do
  nonIOMeta <- meta
  if S.null decs then do
    if isInFunction nonIOMeta
      then do return (return (RETURN_EVAL EVAL_NIL), meta)
      else do return (return prev, meta)
  else do
    (ev, newMeta) <- evalDeclaration (S.index decs 0) meta
    --print ev
    --print newMeta
    if isInFunction newMeta && isReturn ev
      then do return(return ev, meta)
      else do
       if isRuntimeError ev
         then do
           print ev
           return (return ev, meta)
          else do
            eval (S.drop 1 decs) ev (return newMeta)



evalDeclaration :: DECLARATION -> IO META -> IO (EVAL, META)
evalDeclaration (DEC_STMT (PRINT_STMT x)) meta = do
  locMeta <- meta
  (expr, newMeta) <- evalExpression x locMeta
  print expr
  return (expr, locMeta)
evalDeclaration (DEC_STMT (EXPR_STMT x)) meta = do
  locMeta <- meta
  evalExpression x locMeta
evalDeclaration (DEC_VAR (VAR_DEC_DEF (TH.IDENTIFIER iden) expr)) meta = do
  locMeta <- meta
  (locExpr, newMeta) <- evalExpression expr locMeta
  handleVarDeclarationAndDefinition iden locExpr newMeta
evalDeclaration (DEC_VAR (VAR_DEC (TH.IDENTIFIER iden))) meta = do
  locMeta <- meta
  handleVarDeclaration iden locMeta
evalDeclaration (DEC_VAR (VAR_DEF (TH.IDENTIFIER iden) expr tokens)) meta = do
  locMeta <- meta
  (locExpr, newMeta) <- evalExpression expr locMeta
  handleVarDefinition iden locExpr newMeta tokens
evalDeclaration (DEC_STMT (BLOCK_STMT x)) meta = do
  locMeta <- meta
  (evIO, newMetaIO) <- evalBlock x locMeta
  newMeta <- newMetaIO
  ev <- evIO
  return (ev, newMeta)
evalDeclaration (DEC_STMT (IF_STMT expr stmt)) meta = do
  locMeta <- meta
  (exprVal, newMeta) <- evalExpression expr locMeta
  print exprVal
  print (maybeEvalTruthy exprVal)
  print stmt
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
  nonIOMeta <- meta
  let locMetaIO =  updateMetaWithLocalEnv nonIOMeta
  (ev, decMeta) <- evalDeclaration varDec locMetaIO
  if isRuntimeError ev then do
    return (ev, nonIOMeta)
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

evalDeclaration (DEC_FUNC (FUNC_DEC (TH.IDENTIFIER iden) (PARAMETERS params) stmt)) meta = do
  locMeta <- meta
  let eval = FUNC_DEC_EVAL iden (S.length params) (PARAMETERS params) stmt
  newMeta <- addIdentifierToMetaEnv iden eval locMeta
  return (eval, newMeta)

evalDeclaration (DEC_STMT (RETURN expr)) meta = do
  locMeta <- meta
  (ev, newMeta) <- evalExpression expr locMeta
  print "this is called"
  print ev
  return (ev, newMeta)

evalDeclaration (DEC_STMT RETURN_NIL) meta = do
  locMeta <- meta
  return (EVAL_NIL, locMeta)

evalDeclaration x meta = do
  locMeta <- meta
  print x
  return (RUNTIME_ERROR "Unknown error occured" S.empty, locMeta)


-- Think about redefinement
handleVarDeclaration :: TextType -> META -> IO (EVAL, META)
handleVarDeclaration iden meta = do
  newMeta <- addIdentifierToMetaEnv iden EVAL_NIL meta
  return (DEC_EVAL iden EVAL_NIL, newMeta)

handleVarDeclarationAndDefinition :: TextType -> EVAL -> META -> IO (EVAL, META)
handleVarDeclarationAndDefinition iden val meta = do
  newMeta <- addIdentifierToMetaEnv iden val meta
  return (DEC_EVAL iden val, newMeta)

handleVarDefinition :: TextType -> EVAL -> META -> S.Seq TH.Token -> IO (EVAL, META)
handleVarDefinition iden val meta tokens = do
  (newMeta, isSuccess) <- updateIdentifierToMetaEnv iden val meta
  if isSuccess then return (DEC_EVAL iden val, newMeta) else return (RUNTIME_ERROR "Identifier is not defined" tokens, meta)





evalExpression :: EXPRESSION -> META -> IO (EVAL, META)
evalExpression (EXP_LITERAL (NUMBER x)) meta = return (EVAL_NUMBER x, meta)
evalExpression (EXP_LITERAL (STRING x)) meta = return (EVAL_STRING x, meta)
evalExpression (EXP_LITERAL FALSE) meta = return (EVAL_BOOL False, meta)
evalExpression (EXP_LITERAL TRUE) meta = return (EVAL_BOOL True, meta)
evalExpression (EXP_LITERAL NIL) meta = return (EVAL_NIL, meta)
evalExpression (EXP_LITERAL (IDENTIFIER x tokens)) meta = do
  val <- findValueInMetaEnv x meta
  if isJust val then return (fromJust val, meta) else return (RUNTIME_ERROR "Identifier is not defined" tokens, meta)

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

evalExpression (EXP_CALL (CALL_FUNC exp args)) meta = do
  (eval, newMeta) <- evalExpression exp meta
  evalFunctions newMeta eval args

evalExpression _ meta = return (RUNTIME_ERROR "Expression cannot be evaluated" (S.fromList []), meta)



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



callFunction :: META -> EVAL -> ARGUMENTS ->IO (EVAL, META)
callFunction meta (FUNC_DEC_EVAL iden arity params stmt) (ARGS args)
  | S.length args /= arity = return (RUNTIME_ERROR (T.pack (mconcat ["Expected ", show arity, " arguments", ", but got ", show argsLength])) S.empty, meta)
  | otherwise = functionCall meta iden params (ARGS args) stmt
  where argsLength = S.length args


functionCall :: META -> AST.TextType -> PARAMETERS -> ARGUMENTS -> FUNCTION_STATEMENT -> IO (EVAL, META)
functionCall meta iden params args (FUNC_STMT (BLOCK_STMT decs)) = do
  locMeta <- updateMetaWithLocalEnv meta
  savedMeta <- saveFunctionArgs locMeta params args
  (pIO, locMetaIO) <- eval decs SKIP_EVAL (return savedMeta{isInFunction=True, isInLoop=False})
  locMeta <- locMetaIO
  let newMeta = deleteLocalEnvFromMeta locMeta
  returnEval <- pIO
  let evalValue = getValueFromReturn returnEval
  return (evalValue, newMeta{isInFunction=(isInFunction meta), isInLoop=(isInLoop meta)})
functionCall meta iden params args (NATIVE_FUNC_STMT f) = do
  eval <- callNativeFunction f args
  return (eval, meta)


saveFunctionArgs :: META -> PARAMETERS -> ARGUMENTS -> IO META
saveFunctionArgs meta (PARAMETERS params) (ARGS args)
 | S.null params = return meta
 | otherwise = do
     let (EXP_LITERAL (IDENTIFIER p b)) = S.index params 0
     let a = S.index args 0
     (evalA, evalMeta) <- evalExpression a meta
     newMeta <- addIdentifierToMetaEnv p evalA evalMeta
     saveFunctionArgs newMeta (PARAMETERS (S.drop 1 params)) (ARGS (S.drop 1 args))

callNativeFunction :: NATIVE_FUNCTION_TYPES -> ARGUMENTS -> IO EVAL
callNativeFunction (CLOCK x) params = do
  val <- (x id)
  return (EVAL_NUMBER (fromInteger val))

returnFromLoop newEv newMeta = isRuntimeError newEv || (isInFunction newMeta && isReturn newEv)
