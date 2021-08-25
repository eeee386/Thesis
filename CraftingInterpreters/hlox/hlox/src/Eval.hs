{-# LANGUAGE OverloadedStrings #-}

module Eval where
  
import AST
import qualified Data.Text as T
import Data.Maybe
import qualified Data.Sequence as S
import qualified TokenHelper as TH
import EvalTypes
import Environment
  
evalProgram :: PROGRAM -> IO ()
evalProgram (PROG x) = do 
  eval x SKIP_EVAL createGlobalEnvironment
  return ()

evalBlock :: S.Seq DECLARATION -> Environments -> IO (IO PROG_EVAL, IO Environments)
evalBlock x env = do
  (pIO, envIO) <- eval x SKIP_EVAL (createLocalEnvironment env)
  let newEnvIO = deleteLocalEnvironment <$> envIO
  return (pIO, newEnvIO)


eval :: S.Seq DECLARATION -> PROG_EVAL -> IO Environments -> IO (IO PROG_EVAL, IO Environments)
eval decs prev env = do
  if 
    S.null decs 
  then do 
    return (return prev, env) 
  else do
    (ev, newEnv) <- evalProgramHelper (S.index decs 0) env
    if 
      hasRuntimeError ev 
    then do
      runRuntimeError (createRuntimeError ev)
      return (return ev, env)
    else do
      eval (S.drop 1 decs) ev (return newEnv)


evalProgramHelper :: DECLARATION -> IO Environments -> IO (PROG_EVAL, Environments) 
evalProgramHelper (DEC_STMT (PRINT_STMT x)) env = do 
  locEnv <- env
  expr <- evalExpression x locEnv
  print expr
  return (PRINT_EVAL expr, locEnv)
evalProgramHelper (DEC_STMT (EXPR_STMT x)) env = do 
  locEnv <- env
  expr <- evalExpression x locEnv
  return (EXPR_EVAL expr, locEnv)
evalProgramHelper (DEC_VAR (VAR_DEC_DEF (TH.IDENTIFIER iden) expr)) env = do 
  locEnv <- env
  locExpr <- evalExpression expr locEnv
  handleVarDeclarationAndDefinition iden locExpr locEnv
evalProgramHelper (DEC_VAR (VAR_DEC (TH.IDENTIFIER iden))) env = do 
  locEnv <- env
  handleVarDeclaration iden locEnv
evalProgramHelper (DEC_VAR (VAR_DEF (TH.IDENTIFIER iden) expr tokens)) env = do 
  locEnv <- env
  locExpr <- evalExpression expr locEnv
  handleVarDefinition iden locExpr locEnv tokens 
evalProgramHelper (DEC_STMT (BLOCK_STMT x)) env = do
  locEnv <- env
  (evIO, newEnvIO) <- evalBlock x locEnv
  newEnv <- newEnvIO
  ev <- evIO
  return (ev, newEnv)
evalProgramHelper (DEC_STMT (IF_STMT expr stmt)) env = do
  locEnv <- env
  exprVal <- evalExpression expr locEnv
  if maybeEvalTruthy exprVal == Just True then evalProgramHelper (createDecFromStatementForIf stmt) env else return (SKIP_EVAL, locEnv)  
evalProgramHelper (DEC_STMT (IF_ELSE_STMT expr stmt1 stmt2)) env = do
  locEnv <- env
  exprVal <- evalExpression expr locEnv
  if maybeEvalTruthy exprVal == Just True then evalProgramHelper (createDecFromStatementForIf stmt1) env else evalProgramHelper (createDecFromStatementForIf stmt2) env 
evalProgramHelper (DEC_STMT (WHILE_STMT expr stmt)) env = do
  locEnv <- env
  exprVal <- evalExpression expr locEnv
  if maybeEvalTruthy exprVal == Just True then do 
    (_, newEnv) <- evalProgramHelper (createDecFromStatementForIf stmt) env
    evalProgramHelper (DEC_STMT (WHILE_STMT expr stmt)) (return newEnv)
  else return (SKIP_EVAL, locEnv) 

evalProgramHelper x env = do
  locEnv <- env
  print x
  return (EXPR_EVAL (NON_EVAL "Unknown error occured" S.empty), locEnv)

handleVarDeclaration :: TextType -> Environments -> IO (PROG_EVAL, Environments)
handleVarDeclaration iden env = do
  newEnv <- addIdentifierToEnvironment iden EVAL_NIL env
  return (DEC_EVAL iden EVAL_NIL, newEnv)

handleVarDeclarationAndDefinition :: TextType -> EVAL -> Environments -> IO (PROG_EVAL, Environments)
handleVarDeclarationAndDefinition iden val env = do
  newEnv <- addIdentifierToEnvironment iden val env
  return (DEC_EVAL iden val, newEnv)  
  
handleVarDefinition :: TextType -> EVAL -> Environments -> S.Seq TH.Token -> IO (PROG_EVAL, Environments)
handleVarDefinition iden val env tokens = do
  (newEnv, isSuccess) <- updateIdentifierToEnvironment iden val env
  if isSuccess then return (DEC_EVAL iden val, newEnv) else return (DEC_EVAL iden (NON_EVAL "Identifier is not defined" tokens), env)
    

evalExpression :: EXPRESSION -> Environments -> IO EVAL
evalExpression (EXP_LITERAL (NUMBER x)) _ = return (EVAL_NUMBER x)
evalExpression (EXP_LITERAL (STRING x)) _ = return (EVAL_STRING x)
evalExpression (EXP_LITERAL FALSE) _ = return (EVAL_BOOL False)
evalExpression (EXP_LITERAL TRUE) _ = return (EVAL_BOOL True)
evalExpression (EXP_LITERAL NIL) _ = return EVAL_NIL
evalExpression (EXP_LITERAL (IDENTIFIER x tokens)) env = do 
  val <- findValueOfIdentifier x env
  if isJust val then return (fromJust val) else return (NON_EVAL "Identifier is not defined" tokens) 

evalExpression (EXP_GROUPING (GROUP x)) env = evalExpression x env

evalExpression (EXP_UNARY (UNARY op x) tokens) env = do 
  expr <- evalExpression x env
  return (evalUnary tokens op expr) 

evalExpression (EXP_BINARY (BIN left op right) bLines) env = do 
  evaledLeft <- evalExpression left env
  evaledRight <- evalExpression right env
  return (evalBinary bLines evaledLeft op evaledRight) 

evalExpression (EXP_TERNARY (TERN predi _ trueRes _ falseRes) tLines) env = do 
  evalTrueRes <- evalExpression trueRes env
  evalFalseRes <- evalExpression falseRes env
  evalPred <- evalExpression predi env 
  return (evalTernary tLines evalPred evalTrueRes evalFalseRes)

evalExpression _ _ = return (NON_EVAL "Expression cannot be evaluated" (S.fromList []))


evalUnary :: S.Seq TH.Token -> OPERATOR -> EVAL -> EVAL
evalUnary tokens op expr
  | op == AST.MINUS && isJust valNum = EVAL_NUMBER (-(fromJust valNum))
  | op == AST.BANG && isJust valTruthy = EVAL_BOOL (not (fromJust valTruthy))
  | otherwise = NON_EVAL "Operand must be a number" tokens
  where valNum = maybeEvalNumber expr
        valTruthy = maybeEvalTruthy expr
  
  

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
         | otherwise = NON_EVAL "Operands must be two numbers or two strings" tokens


evalTernary :: S.Seq TH.Token -> EVAL -> EVAL -> EVAL -> EVAL
evalTernary tokens predi trueRes falseRes
  | preppedPred == Just True = trueRes
  | preppedPred == Just False = falseRes
  | otherwise = NON_EVAL "Ternary operator failed" tokens
  where preppedPred = maybeEvalTruthy predi

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
createMathOp x tokens l r f = if isJust l && isJust r then x (f (fromJust l) (fromJust r)) else NON_EVAL "Operands must be numbers" tokens

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

createDecFromStatementForIf :: STATEMENT -> DECLARATION
createDecFromStatementForIf (EXPR_STMT x) = DEC_STMT (EXPR_STMT x)
createDecFromStatementForIf (PRINT_STMT x) = DEC_STMT (PRINT_STMT x)
createDecFromStatementForIf (BLOCK_STMT xs) = DEC_STMT (BLOCK_STMT xs)
createDecFromStatementForIf (IF_STMT ex st) = DEC_STMT (IF_STMT ex st)
createDecFromStatementForIf (IF_ELSE_STMT ex st1 st2) = DEC_STMT (IF_ELSE_STMT ex st1 st2)