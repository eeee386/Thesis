{-# LANGUAGE OverloadedStrings #-}

module Eval where
  
import AST
import qualified Data.Text as T
import Data.Maybe
import qualified Data.Sequence as S
import qualified TokenHelper as TH


type Line = Int
type Lines = (Line, Line)

-- TODO: show line in error message, have to refactor parser and AST for this

data EVAL = EVAL_NUMBER Double | EVAL_STRING AST.TextType | EVAL_BOOL Bool | EVAL_NIL | NON_EVAL AST.TextType (S.Seq TH.Token) deriving Eq
instance Show EVAL where
  show (EVAL_NUMBER x) = show x
  show (EVAL_STRING x) = show x
  show (EVAL_BOOL x) = show x
  show EVAL_NIL = "nil"
  show (NON_EVAL x neLines) = mconcat ["RuntimeError: ", show x, getLineError neLines]
  

evalExpression :: EXPRESSION -> EVAL
evalExpression (EXP_LITERAL (NUMBER x)) = EVAL_NUMBER x
evalExpression (EXP_LITERAL (STRING x)) = EVAL_STRING x
evalExpression (EXP_LITERAL FALSE) = EVAL_BOOL False
evalExpression (EXP_LITERAL TRUE) = EVAL_BOOL True
evalExpression (EXP_LITERAL NIL) = EVAL_NIL
evalExpression (EXP_GROUPING (GROUP x)) = evalExpression x
evalExpression (EXP_UNARY x tokens) = getUnary tokens x 
evalExpression (EXP_BINARY (BIN left op right) bLines) = getBinary bLines left op right 
evalExpression (EXP_TERNARY (TERN predi _ trueRes _ falseRes) tLines) = getTernary tLines predi trueRes falseRes
evalExpression _ = NON_EVAL "Expression cannot be evaluated" (S.fromList [])

getUnary :: S.Seq TH.Token -> UNARY -> EVAL
getUnary tokens (UNARY_BANG x) 
  | isJust val = EVAL_BOOL (not (fromJust val))
  | otherwise = NON_EVAL "Not an expression" tokens
  where val = maybeEvalTruthy (evalExpression x)
getUnary tokens (UNARY_MINUS x) 
  | isJust number = EVAL_NUMBER (-(fromJust number))
  | otherwise = NON_EVAL "Operand must be a number" tokens
  where number = maybeEvalNumber (evalExpression x)
  

getBinary :: S.Seq TH.Token -> EXPRESSION -> OPERATOR -> EXPRESSION ->  EVAL
getBinary tokens left op right
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
 where evalLeft = evalExpression left
       evalRight = evalExpression right
       leftNum = maybeEvalNumber evalLeft
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


getTernary :: S.Seq TH.Token -> EXPRESSION -> EXPRESSION -> EXPRESSION -> EVAL
getTernary tokens predi trueRes falseRes
  | preppedPred == Just True = evalExpression trueRes
  | preppedPred == Just False = evalExpression falseRes
  | isNothing preppedPred = NON_EVAL "Ternary operator failed" tokens
  where preppedPred = maybeEvalTruthy (evalExpression predi)

-- Helpers
getLineError :: S.Seq TH.Token -> String
getLineError tokens = if firstLine /= secondLine then mconcat [". Between lines: ", show firstLine, "-", show secondLine] else mconcat [". In line: ", show firstLine]
  where firstLine = TH.line (S.index tokens 0) 
        secondLine = TH.line (S.index tokens (S.length tokens - 1))
 
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

createEquality :: (Eq a) => a -> a -> (Bool -> Bool) -> EVAL
createEquality l r ch = if l == r then EVAL_BOOL (ch True) else EVAL_BOOL False
  