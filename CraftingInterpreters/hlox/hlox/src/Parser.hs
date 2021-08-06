module Parser where

import AST
import qualified Data.Sequence as S
import TokenHelper

parse :: S.Seq Token -> EXPRESSION
parse = createExpression 0

createExpression :: Int -> S.Seq Token -> EXPRESSION
createExpression = createEquality

createEquality :: Int -> S.Seq Token -> EXPRESSION
createEquality index tokens = if op /= AST.NO_OP then EXP_BINARY (BIN (createComparison index tokens) op right) else createComparison index tokens
  where
    token = tokenType (S.index tokens index)
    buildEquality :: Int -> S.Seq Token -> (OPERATOR, EXPRESSION)
    buildEquality ind tokenList
      | token == TokenHelper.EQUAL_EQUAL = (AST.EQUAL_EQUAL, createEquality (ind + 1) tokenList)
      | token == TokenHelper.BANG_EQUAL = (AST.BANG_EQUAL, createEquality (ind + 1) tokenList)
      | otherwise = (AST.NO_OP, AST.NON_EXP)
    res = buildEquality (index + 1) tokens
    op = fst res
    right = snd res

createComparison :: Int -> S.Seq Token -> EXPRESSION
createComparison index tokens = if op /= AST.NO_OP then EXP_BINARY (BIN (createTerm index tokens) op right) else createTerm index tokens
  where
    token = tokenType (S.index tokens index)
    buildComparison :: Int -> S.Seq Token -> (OPERATOR, EXPRESSION)
    buildComparison ind tokenList
      | token == TokenHelper.LESS = (AST.LESS, createComparison (ind + 1) tokenList)
      | token == TokenHelper.LESS_EQUAL = (AST.LESS_EQUAL, createComparison (ind + 1) tokenList)
      | token == TokenHelper.GREATER = (AST.GREATER, createComparison (ind + 1) tokenList)
      | token == TokenHelper.GREATER_EQUAL = (AST.GREATER_EQUAL, createComparison (ind + 1) tokenList)
      | otherwise = (AST.NO_OP, AST.NON_EXP)
    res = buildComparison (index + 1) tokens
    op = fst res
    right = snd res

createTerm :: Int -> S.Seq Token -> EXPRESSION
createTerm index tokens = if op /= AST.NO_OP then EXP_BINARY (BIN (createFactor index tokens) op right) else createFactor index tokens
  where
    token = tokenType (S.index tokens index)
    buildTerm :: Int -> S.Seq Token -> (OPERATOR, EXPRESSION)
    buildTerm ind tokenList
      | token == TokenHelper.PLUS = (AST.PLUS, createTerm (ind + 1) tokenList)
      | token == TokenHelper.MINUS = (AST.MINUS, createTerm (ind + 1) tokenList)
      | otherwise = (AST.NO_OP, AST.NON_EXP)
    res = buildTerm (index + 1) tokens
    op = fst res
    right = snd res

createFactor :: Int -> S.Seq Token -> EXPRESSION
createFactor index tokens = if op /= AST.NO_OP then EXP_BINARY (BIN (createUnary index tokens) op right) else createUnary index tokens
  where
    token = tokenType (S.index tokens index)
    buildFactor :: Int -> S.Seq Token -> (OPERATOR, EXPRESSION)
    buildFactor ind tokenList
      | token == TokenHelper.SLASH = (AST.SLASH, createFactor (ind + 1) tokenList)
      | token == TokenHelper.STAR = (AST.STAR, createFactor (ind + 1) tokenList)
      | otherwise = (AST.NO_OP, AST.NON_EXP)
    res = buildFactor (index + 1) tokens
    op = fst res
    right = snd res
    
createUnary :: Int -> S.Seq Token -> EXPRESSION
createUnary index tokens
  | token == TokenHelper.BANG = EXP_UNARY (UNARY_BANG (createUnary (index+1) tokens))
  | token == TokenHelper.MINUS = EXP_UNARY (UNARY_MINUS (createUnary (index+1) tokens))
  | otherwise = createLiteral index tokens
  where token = tokenType (S.index tokens index)
  
createLiteral :: Int -> S.Seq Token -> EXPRESSION
createLiteral index tokens = checkLiteralToken token index tokens
  where token = tokenType (S.index tokens index)

checkLiteralToken :: TokenType -> Int -> S.Seq Token -> EXPRESSION
checkLiteralToken (TokenHelper.STRING a) _ _ = EXP_LITERAL (AST.STRING a)
checkLiteralToken (TokenHelper.NUMBER a) _ _  = EXP_LITERAL (AST.NUMBER a)
checkLiteralToken TokenHelper.FALSE _ _  = EXP_LITERAL AST.FALSE
checkLiteralToken TokenHelper.TRUE _ _  = EXP_LITERAL AST.TRUE
checkLiteralToken TokenHelper.NIL _ _ = EXP_LITERAL AST.NIL
checkLiteralToken TokenHelper.LEFT_PAREN index tokens = EXP_GROUPING (GROUP (if isEof then NON_EXP else createExpression (index+expLength) tokens)) 
  where tokensToUse = S.takeWhileL (\x -> tokenType x /= TokenHelper.LEFT_PAREN) tokens
        expLength = S.length tokensToUse
        eofFind = S.findIndexR (\x -> tokenType x == EOF) tokensToUse
        isEof = getIsAnyEOF eofFind
checkLiteralToken _ _ _ = NON_EXP

getIsAnyEOF :: Maybe Int -> Bool
getIsAnyEOF (Just _) = True
getIsAnyEOF Nothing = False