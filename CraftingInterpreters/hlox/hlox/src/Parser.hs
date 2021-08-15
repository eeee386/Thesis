{-# LANGUAGE OverloadedStrings #-}

module Parser where

import AST
import qualified Data.Sequence as S
import TokenHelper
import Data.Maybe
import qualified Data.Map as M


 
-- TODO: solve Synchronization 

parse :: S.Seq Token -> PROGRAM
parse = createProgram

createProgram :: S.Seq Token -> PROGRAM
createProgram tokens
  | tokenType eofToken /= EOF = PROG_ERROR (PARSE_ERROR "Unterminated statement" eofStmtToken)
  | otherwise = PROG (createDeclaration (S.take (S.length stmtTokens-1) stmtTokens) S.empty) eofToken
  where stmtTokens = breakIntoStatements tokens
        eofStmtToken = S.index stmtTokens (S.length stmtTokens-1)
        eofToken = S.index eofStmtToken 0
        
createDeclaration :: S.Seq (S.Seq Token) -> S.Seq DECLARATION -> S.Seq DECLARATION      
createDeclaration stmtTokens decSeq
  | S.null stmtTokens = decSeq
  | otherwise = createDeclaration (S.drop 1 stmtTokens) expressions
  where expressions = decSeq S.|> dec
        expr = S.index stmtTokens 0
        dec = handleCreateDeclaration expr

handleCreateDeclaration :: S.Seq Token -> DECLARATION         
handleCreateDeclaration expr
  | isDec && isDefToo && hasIden && hasVal = DEC_VAR (VAR_DEC_DEF (fromJust iden) (createExpression defExpr))
  | isDec && hasIden && not hasVal && not isDefToo = DEC_VAR (VAR_DEC (fromJust iden))
  | isPrint = DEC_STMT (PRINT_STMT (createExpression expr))
  | isExpressionStatement = DEC_STMT (EXPR_STMT (createExpression expr))
  | otherwise = PARSE_ERROR "Not a valid declaration or expression" expr
  where firstToken = S.lookup 0 expr
        firstTokenType = tokenType <$> firstToken
        iden = tokenType <$> S.lookup 1 expr
        eqToken = S.lookup 2 expr
        defExpr = S.drop 3 expr
        isDec = firstTokenType == Just VAR 
        isDefToo = (tokenType <$> eqToken) == Just EQUAL
        hasIden = isJust iden
        hasVal = S.null defExpr
        isPrint = firstTokenType == Just PRINT
        isExpressionStatement = firstTokenType /= Just VAR || firstTokenType /= Just PRINT
                
                

createExpression :: S.Seq Token -> EXPRESSION
createExpression = createTernary

-- Other cases could be covered, such one of the operators missing
-- Could be problematic if we had used question marks and colons as other operands
createTernary :: S.Seq Token -> EXPRESSION
createTernary tokens = handleTernaryCases getOp1 getOp2 indexOfOp1 indexOfOp2 tokens
  where 
    indexOfOp1 = S.findIndexL (\x -> tokenType x == TokenHelper.QUESTION_MARK) tokens
    indexOfOp2 = S.findIndexL (\x -> tokenType x == TokenHelper.COLON) tokens
    getOp1 indx 
      | tokenType (S.index tokens indx) == TokenHelper.QUESTION_MARK = AST.QUESTION_MARK
    getOp2 indx 
      | tokenType (S.index tokens indx) == TokenHelper.COLON = AST.COLON


createEquality :: S.Seq Token -> EXPRESSION
createEquality = createBinaryExpressions (M.fromList [(TokenHelper.EQUAL_EQUAL, AST.EQUAL_EQUAL), 
                                                      (TokenHelper.BANG_EQUAL, AST.BANG_EQUAL)]) createComparison

createComparison :: S.Seq Token -> EXPRESSION
createComparison = createBinaryExpressions (M.fromList [(TokenHelper.LESS, AST.LESS),
                                                        (TokenHelper.LESS_EQUAL, AST.LESS_EQUAL),
                                                        (TokenHelper.GREATER, AST.GREATER),
                                                        (TokenHelper.GREATER_EQUAL, AST.GREATER_EQUAL)]) createTerm

createTerm :: S.Seq Token -> EXPRESSION
createTerm = createBinaryExpressions (M.fromList [(TokenHelper.PLUS, AST.PLUS), 
                                                  (TokenHelper.MINUS, AST.MINUS)]) createFactor

createFactor :: S.Seq Token -> EXPRESSION
createFactor = createBinaryExpressions (M.fromList [(TokenHelper.SLASH, AST.SLASH), 
                                                    (TokenHelper.STAR, AST.STAR)]) createUnary

    
createUnary :: S.Seq Token -> EXPRESSION
createUnary tokens
  | tType == Just TokenHelper.BANG = EXP_UNARY (UNARY_BANG (createUnary (S.drop 1 tokens))) tokens
  | tType == Just TokenHelper.MINUS = EXP_UNARY (UNARY_MINUS (createUnary (S.drop 1 tokens))) tokens
  | otherwise = createLiteral tokens
  where token = S.lookup 0 tokens
        tType = tokenType <$> token
  
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
  | isEof = NON_EXP "Parenthesis not closed" tokens
  | isEmpty = NON_EXP "Empty parenthesis" tokens
  | otherwise = EXP_GROUPING (GROUP (createExpression tokensToUse))
  where tokensToMatch = S.takeWhileL (\x -> tokenType x /= TokenHelper.RIGHT_PAREN) tokens
        tokensToUse = S.drop 1 tokensToMatch
        eofFind = S.findIndexR (\x -> tokenType x == SEMICOLON) tokensToMatch
        isEof = getIsAnyEOF eofFind
        isEmpty = S.null tokensToUse
checkLiteralToken _ tokens = NON_EXP "Misplaced Token" tokens


--Helpers
findFromIndex :: Int -> (a -> Bool) -> S.Seq a -> Maybe Int
findFromIndex start predi tokens = S.findIndexL predi (S.drop start tokens) 

getIsAnyEOF :: Maybe Int -> Bool
getIsAnyEOF (Just _) = True
getIsAnyEOF Nothing = False

createBinaryExpressions :: M.Map TokenType OPERATOR -> (S.Seq Token -> EXPRESSION) -> S.Seq Token -> EXPRESSION
createBinaryExpressions tokenExpMap nextPrec tokens = handleBinaryCases
  where
    indexOfOp = S.findIndexL (\x -> tokenType x `elem` M.keys tokenExpMap) tokens
    bin = prepBinary getOp (fromJust indexOfOp) tokens nextPrec
    getOp indx = tokenExpMap M.! token
      where token = tokenType (S.index tokens indx)
    handleBinaryCases
      | isJust indexOfOp && indexOfOp > Just 0 = EXP_BINARY bin tokens
      | indexOfOp > Just (S.length tokens - 2) = NON_EXP "Missing operands from right side" tokens
      | otherwise = nextPrec tokens

prepBinary :: (Int -> OPERATOR) -> Int -> S.Seq Token -> (S.Seq Token -> EXPRESSION) -> BINARY
prepBinary getOperation idx tokens nextPrec = AST.BIN (nextPrec left) op (nextPrec right)
   where split = splitTokens idx
         left = fst split
         right = S.drop 1 (snd split) 
         op = getOperation idx
         splitTokens indx = S.splitAt indx tokens
         
prepTernary :: (Int -> OPERATOR) -> (Int -> OPERATOR) -> Int -> Int -> S.Seq Token -> (S.Seq Token -> EXPRESSION) -> TERNARY
prepTernary getOp1 getOp2 idx1 idx2 tokens nextPrec = AST.TERN (nextPrec left) op1 (nextPrec middle) op2 (nextPrec right)
  where splitTokens indx tList = S.splitAt indx tList
        split1 = splitTokens idx1 tokens
        left = fst split1
        rest = S.drop 1 (snd split1)
        split2 = splitTokens (idx2-idx1-1) rest
        middle = fst split2
        right = S.drop 1 (snd split2)
        op1 = getOp1 idx1
        op2 = getOp2 idx2


handleTernaryCases :: (Int -> OPERATOR) -> (Int -> OPERATOR) -> Maybe Int -> Maybe Int -> S.Seq Token -> EXPRESSION
handleTernaryCases getOp1 getOp2 indexOfOp1 indexOfOp2 tokens
  | bothIsJust && properPlacement = EXP_TERNARY tern tokens
  | xorIsJust || (bothIsJust && not properPlacement) = NON_EXP "Not a valid ternary operator" tokens
  | otherwise = createEquality tokens
  where tern = prepTernary getOp1 getOp2 (fromJust indexOfOp1) (fromJust indexOfOp2) tokens createEquality
        bothIsJust = isJust indexOfOp1 && isJust indexOfOp2
        xorIsJust = isJust indexOfOp1 /= isJust indexOfOp2
        properPlacement = ((-) <$> indexOfOp2 <*> indexOfOp1) > Just 1 && indexOfOp2 < Just (S.length tokens - 2)
   
breakIntoStatements :: S.Seq Token -> S.Seq (S.Seq Token)     
breakIntoStatements = breakTokens statements
  where statements = S.empty

breakTokens :: S.Seq (S.Seq Token) -> S.Seq Token -> S.Seq (S.Seq Token)
breakTokens stmts tokens 
  | S.null right = newStmts
  | otherwise = breakTokens newStmts right
  where scIndex = S.findIndexL (\x -> tokenType x == SEMICOLON) tokens
        (left, right) = if isJust scIndex then S.splitAt (fromJust scIndex+1) tokens else (tokens, S.empty)
        newStmts = stmts S.|> left
        
findASTError :: EXPRESSION -> Maybe String
findASTError (NON_EXP x y) = Just (show (NON_EXP x y))
findASTError (EXP_GROUPING (GROUP x)) = findASTError x
findASTError (EXP_UNARY (UNARY_MINUS x) _) = findASTError x
findASTError (EXP_UNARY (UNARY_BANG x) _) = findASTError x
findASTError (EXP_BINARY (BIN left _ right) _) = (++) <$> findASTError left <*> findASTError right
findASTError (EXP_TERNARY (TERN _ _ trueRes _ falseRes) _) = (++) <$> findASTError trueRes <*> findASTError falseRes
findASTError _ = Nothing
        