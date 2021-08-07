{-# LANGUAGE OverloadedStrings #-}

module Parser where

import AST
import qualified Data.Sequence as S
import TokenHelper
import Data.Maybe

-- TODO: Add ternary operator

parse :: S.Seq Token -> EXPRESSION
parse = createExpression

createExpression :: S.Seq Token -> EXPRESSION
createExpression = createEquality

createEquality :: S.Seq Token -> EXPRESSION
createEquality tokens = if isJust indexOfOp then EXP_BINARY (prepBinary getOp (fromJust indexOfOp) tokens createComparison) else createComparison tokens
  where
    indexOfOp = S.findIndexL (\x -> tokenType x == TokenHelper.EQUAL_EQUAL || tokenType x == TokenHelper.BANG_EQUAL) tokens
    getOp indx 
      | token == TokenHelper.EQUAL_EQUAL = AST.EQUAL_EQUAL
      | token == TokenHelper.BANG_EQUAL = AST.BANG_EQUAL
      where token = tokenType (S.index tokens indx)

createComparison :: S.Seq Token -> EXPRESSION
createComparison tokens = if isJust indexOfOp then EXP_BINARY (prepBinary getOp (fromJust indexOfOp) tokens createTerm) else createTerm tokens
  where
    indexOfOp = S.findIndexL (\x -> tokenType x == TokenHelper.LESS || tokenType x == TokenHelper.LESS_EQUAL || tokenType x == TokenHelper.GREATER || tokenType x == TokenHelper.GREATER_EQUAL) tokens
    getOp indx 
      | token == TokenHelper.LESS = AST.LESS
      | token == TokenHelper.LESS_EQUAL = AST.LESS_EQUAL
      | token == TokenHelper.GREATER = AST.GREATER
      | token == TokenHelper.GREATER_EQUAL = AST.GREATER_EQUAL
      where token = tokenType (S.index tokens indx)

createTerm :: S.Seq Token -> EXPRESSION
createTerm tokens = if isJust indexOfOp then EXP_BINARY (prepBinary getOp (fromJust indexOfOp) tokens createFactor) else createFactor tokens
  where
    indexOfOp = S.findIndexL (\x -> tokenType x == TokenHelper.PLUS || tokenType x == TokenHelper.MINUS) tokens
    getOp indx 
       | token == TokenHelper.PLUS = AST.PLUS
       | token == TokenHelper.MINUS = AST.MINUS
       where token = tokenType (S.index tokens indx)

createFactor :: S.Seq Token -> EXPRESSION
createFactor tokens = if isJust indexOfOp then EXP_BINARY (prepBinary getOp (fromJust indexOfOp) tokens createUnary) else createUnary tokens
  where
    indexOfOp = S.findIndexL (\x -> tokenType x == TokenHelper.SLASH || tokenType x == TokenHelper.STAR) tokens
    getOp indx 
       | token == TokenHelper.SLASH = AST.SLASH
       | token == TokenHelper.STAR = AST.STAR
       where token = tokenType (S.index tokens indx)

    
createUnary :: S.Seq Token -> EXPRESSION
createUnary tokens
  | token == TokenHelper.BANG = EXP_UNARY (UNARY_BANG (createUnary (S.drop 1 tokens)))
  | token == TokenHelper.MINUS = EXP_UNARY (UNARY_MINUS (createUnary (S.drop 1 tokens)))
  | otherwise = createLiteral tokens
  where token = tokenType (S.index tokens 0)
  
createLiteral :: S.Seq Token -> EXPRESSION
createLiteral tokens = checkLiteralToken token tokens
  where token = tokenType (S.index tokens 0)

checkLiteralToken :: TokenType -> S.Seq Token -> EXPRESSION
checkLiteralToken (TokenHelper.STRING a) _ = EXP_LITERAL (AST.STRING a)
checkLiteralToken (TokenHelper.NUMBER a) _  = EXP_LITERAL (AST.NUMBER a)
checkLiteralToken TokenHelper.FALSE _  = EXP_LITERAL AST.FALSE
checkLiteralToken TokenHelper.TRUE _  = EXP_LITERAL AST.TRUE
checkLiteralToken TokenHelper.NIL _ = EXP_LITERAL AST.NIL
checkLiteralToken TokenHelper.LEFT_PAREN tokens 
  | isEof = NON_EXP "Parenthesis not closed"
  | isEmpty = NON_EXP "Empty parenthesis"
  | otherwise = EXP_GROUPING (GROUP (createExpression tokensToUse)) 
  where tokensToMatch = S.takeWhileL (\x -> tokenType x /= TokenHelper.RIGHT_PAREN) tokens
        tokensToUse = S.drop 1 tokensToMatch
        eofFind = S.findIndexR (\x -> tokenType x == EOF) tokensToMatch
        isEof = getIsAnyEOF eofFind
        isEmpty = S.null tokensToUse
checkLiteralToken _ _ = NON_EXP "Unknown Token"




--Helpers

getIsAnyEOF :: Maybe Int -> Bool
getIsAnyEOF (Just _) = True
getIsAnyEOF Nothing = False


prepBinary :: (Int -> OPERATOR) -> Int -> S.Seq a -> (S.Seq a -> EXPRESSION) -> BINARY
prepBinary getOperation idx tokens nextPrec = AST.BIN (nextPrec left) op (nextPrec right)
   where split = splitTokens idx
         left = fst split
         right = S.drop 1 (snd split) 
         op = getOperation idx
         splitTokens indx = S.splitAt indx tokens