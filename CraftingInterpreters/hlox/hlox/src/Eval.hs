{-# LANGUAGE OverloadedStrings #-}

module Eval where
  
import AST
import qualified Data.Text as T
import Data.Maybe

data EVAL = EVAL_NUMBER Double | EVAL_STRING AST.TextType | EVAL_BOOL Bool | EVAL_NIL | NON_EVAL AST.TextType deriving Eq

evalExpression :: EXPRESSION -> EVAL
evalExpression (EXP_LITERAL (NUMBER x)) = EVAL_NUMBER x
evalExpression (EXP_LITERAL (STRING x)) = EVAL_STRING x
evalExpression (EXP_LITERAL FALSE) = EVAL_BOOL False
evalExpression (EXP_LITERAL TRUE) = EVAL_BOOL True
evalExpression (EXP_LITERAL NIL) = EVAL_NIL
evalExpression (EXP_GROUPING (GROUP x)) = evalExpression x
evalExpression (EXP_UNARY x) = getUnary x
evalExpression (EXP_BINARY (BIN left op right)) = getBinary left op right
evalExpression (EXP_TERNARY (TERN predi _ trueRes _ falseRes)) = getTernary predi trueRes falseRes
evalExpression _ = NON_EVAL "Expression cannot be evaluated"

getUnary :: UNARY -> EVAL
getUnary (UNARY_BANG x)
  | isJust val = EVAL_BOOL (not (fromJust val))
  | otherwise = NON_EVAL "Not an expression"
  where val = maybeEvalTruthy (evalExpression x)
getUnary (UNARY_MINUS x)
  | isJust number = EVAL_NUMBER (-(fromJust number))
  | otherwise = NON_EVAL "Not a number expression" 
  where number = maybeEvalNumber (evalExpression x)
  

getBinary :: EXPRESSION -> OPERATOR -> EXPRESSION -> EVAL
getBinary left op right
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
       getArithOp = createArithmeticOps leftNum rightNum
       getCompOp = createComparison leftNum rightNum
       equals = createEquality evalLeft evalRight id
       notEquals = createEquality evalLeft evalRight not
       handlePlus 
         | isJust leftNum && isJust rightNum = getArithOp (+)
         | isJust leftStr && isJust rightStr = concatMaybeString leftStr rightStr
         | otherwise = NON_EVAL ""


getTernary :: EXPRESSION -> EXPRESSION -> EXPRESSION -> EVAL
getTernary predi trueRes falseRes
  | preppedPred == Just True = evalExpression trueRes
  | preppedPred == Just False = evalExpression falseRes
  | isNothing preppedPred = NON_EVAL "Ternary operator failed"
  where preppedPred = maybeEvalTruthy (evalExpression predi)

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

concatMaybeString :: Maybe AST.TextType -> Maybe AST.TextType -> EVAL
concatMaybeString l r = if isJust l && isJust r then EVAL_STRING (T.concat [fromJust l, fromJust r]) else NON_EVAL "Not a concatenation"

createMathOp :: (a -> EVAL) -> Maybe Double -> Maybe Double -> (Double -> Double -> a) -> EVAL
createMathOp x l r f = if isJust l && isJust r then x (f (fromJust l) (fromJust r)) else NON_EVAL "Not an arithmetic operation"

createArithmeticOps :: Maybe Double -> Maybe Double -> (Double -> Double -> Double) -> EVAL
createArithmeticOps = createMathOp EVAL_NUMBER

createComparison :: Maybe Double -> Maybe Double -> (Double -> Double -> Bool) -> EVAL
createComparison = createMathOp EVAL_BOOL

createEquality :: (Eq a) => a -> a -> (Bool -> Bool) -> EVAL
createEquality l r ch = if l == r then EVAL_BOOL (ch True) else EVAL_BOOL False
  