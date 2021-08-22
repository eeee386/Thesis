{-# LANGUAGE OverloadedStrings #-}

module Parser where

import AST
import qualified Data.Sequence as S
import TokenHelper
import Data.Maybe
import qualified Data.Map as M
import Utils

-- Create new file ParseExpressions.hs, take out createExpression and everything under it

parse :: S.Seq Token -> PROGRAM
parse = createProgram

createProgram :: S.Seq Token -> PROGRAM
createProgram tokens = PROG (createDeclarations tokens S.empty)

createDeclarations :: S.Seq Token -> S.Seq DECLARATION -> S.Seq DECLARATION
createDeclarations tokens decSeq 
  | isLastParseError || S.null tokens = decSeq
  | otherwise = createDeclarations rest decSeq S.|> dec
  where isLastParseError = (isParseError <$> getLast decSeq) == Just True
        (dec, rest) = createDeclaration tokens
        
createDeclaration :: S.Seq Token -> (DECLARATION, S.Seq Token)
createDeclaration tokens
  | isIf = handleIf tokens
  | isBlockDec = handleBlock tokens
  | otherwise = handleSimpleDeclaration tokens
  where firstToken = S.lookup 0 tokens
        firstTokenType = tokenType <$> firstToken
        isIf = firstTokenType == Just IF
        isBlockDec = firstTokenType == Just LEFT_BRACE
  
-- Cut tokens in parse errors, because it will cause infinite recursion
handleBlock :: S.Seq Token -> (DECLARATION, S.Seq Token)
handleBlock tokens
  | isClosed = (DEC_STMT (BLOCK_STMT (createDeclarations innerDecTokens S.empty)), right)
  | otherwise = (PARSE_ERROR "Block is not closed" tokens, right)
  where index = S.findIndexR (tokenIsType RIGHT_BRACE) tokens
        isClosed = isJust index
        (left, right) = if isJust index then S.splitAt (fromJust index+1) tokens else (tokens, S.empty)
        innerDecTokens = S.drop 1 (S.take (fromJust index) left)

handleSimpleDeclaration :: S.Seq Token -> (DECLARATION, S.Seq Token)
handleSimpleDeclaration tokens 
  | not isTerminated = (PARSE_ERROR "Statement is not terminated" expr, rest)
  | otherwise = (buildSimpleDecFromTokens expr, rest)
  where index = S.findIndexL (tokenIsType SEMICOLON) tokens
        isTerminated = isJust index
        (expr, rest) = if isTerminated then S.splitAt (fromJust index+1) tokens else (tokens, S.empty)
        
buildSimpleDecFromTokens :: S.Seq Token -> DECLARATION         
buildSimpleDecFromTokens expr
  | isAssignment || isVar = handleAssignmentOrDecDef isVar findAssignment expr firstTokenType
  | isPrint = DEC_STMT (PRINT_STMT (createExpression (S.drop 1 expr)))
  | isExpressionStatement = DEC_STMT (EXPR_STMT (createExpression expr))
  | otherwise = PARSE_ERROR "Not a valid declaration or expression" expr
  where firstToken = S.lookup 0 expr
        firstTokenType = tokenType <$> firstToken
        findAssignment = S.findIndexL (tokenIsType TokenHelper.EQUAL) expr
        isAssignment = isJust findAssignment
        isVar = firstTokenType == Just TokenHelper.VAR
        isPrint = firstTokenType == Just PRINT
        isExpressionStatement = firstTokenType /= Just VAR && firstTokenType /= Just PRINT && firstTokenType /= Just LEFT_BRACE


handleAssignmentOrDecDef :: Bool -> Maybe Int -> S.Seq Token -> Maybe TokenType -> DECLARATION
handleAssignmentOrDecDef isVar findAssignment expr firstTokenType
  | isDecDef = DEC_VAR (VAR_DEC_DEF (fromJust lValue) (createExpression defExpr))
  | isOnlyDec = DEC_VAR (VAR_DEC (fromJust lValue))
  | isRedef = DEC_VAR (VAR_DEF (fromJust lValue) (createExpression redefExpr) redefExpr)
  | otherwise = PARSE_ERROR "Not a valid declaration" expr
  where defExpr = S.drop 3 expr
        redefExpr = S.drop 2 expr
        secondTokenType = tokenType <$> S.lookup 1 expr
        isDec = isVar && (isIdentifier <$> secondTokenType) == Just True
        isOnlyDec = isDec && (tokenType <$> S.lookup 2 expr) == Just TokenHelper.SEMICOLON
        isDecDef = isDec && findAssignment == Just 2 && not (S.null defExpr)
        isRedef = (isIdentifier <$> firstTokenType) == Just True && findAssignment == Just 1 && not (S.null redefExpr)
        lValue
          | isRedef = firstTokenType
          | isDec = secondTokenType
          | otherwise = Nothing
          
handleLValue :: Maybe TokenType -> Maybe TokenType
handleLValue (Just (TokenHelper.IDENTIFIER x)) = Just (TokenHelper.IDENTIFIER changed)
  where changed = id x
handleLValue _ = Nothing

handleIf :: S.Seq Token -> (DECLARATION, S.Seq Token)
handleIf tokens
  | not isLeftParen = (PARSE_ERROR "Parenthesis should after if" tokens, tokens)
  | not isRightParen = (PARSE_ERROR "Parentesis is not closed" tokens, tokens)
  | not isElseToo && isJust ifStmt = (DEC_STMT (IF_STMT expr (fromJust ifStmt)), restToCheck)
  | isElseToo && isJust ifStmt && isJust elseStmt = (DEC_STMT (IF_ELSE_STMT expr (fromJust ifStmt) (fromJust elseStmt)), moreRestToCheck)
  | otherwise = (PARSE_ERROR "Not a valid if statement" tokens, tokens)
  where maybeLeftParen = S.lookup 1 tokens
        isLeftParen = (tokenIsType LEFT_PAREN <$> maybeLeftParen) == Just True
        rightParenIndex = S.findIndexL (tokenIsType RIGHT_PAREN) tokens
        isRightParen = isJust rightParenIndex
        exprTokens = S.drop 2 (S.takeWhileL (not . tokenIsType RIGHT_PAREN) tokens)
        expr = createExpression exprTokens
        nextTokens = S.drop (fromJust rightParenIndex) tokens
        (ifDec, restToCheck) = createDeclaration nextTokens
        ifStmt = getStmtFromDec ifDec
        isElseToo = (tokenType <$> S.lookup 0 restToCheck) == Just ELSE
        (elseDec, moreRestToCheck) = createDeclaration restToCheck
        elseStmt = getStmtFromDec elseDec
        
getStmtFromDec :: DECLARATION -> Maybe STATEMENT
getStmtFromDec (DEC_STMT x) = Just x
getStmtFromDec _ = Nothing

createExpression :: S.Seq Token -> EXPRESSION
createExpression = createTernary

-- Other cases could be covered, such one of the operators missing
-- Could be problematic if we had used question marks and colons as other operands
createTernary :: S.Seq Token -> EXPRESSION
createTernary tokens = handleTernaryCases getOp1 getOp2 indexOfOp1 indexOfOp2 tokens
  where 
    indexOfOp1 = S.findIndexL (tokenIsType TokenHelper.QUESTION_MARK) tokens
    indexOfOp2 = S.findIndexL (tokenIsType TokenHelper.COLON) tokens
    getOp1 indx 
      | tokenType (S.index tokens indx) == TokenHelper.QUESTION_MARK = AST.QUESTION_MARK
    getOp2 indx 
      | tokenType (S.index tokens indx) == TokenHelper.COLON = AST.COLON


createEquality :: S.Seq Token -> EXPRESSION
createEquality = createBinaryExpressions (M.fromList [(TokenHelper.EQUAL_EQUAL, AST.EQUAL_EQUAL), 
                                                      (TokenHelper.BANG_EQUAL, AST.BANG_EQUAL)]) createEquality createComparison

createComparison :: S.Seq Token -> EXPRESSION
createComparison = createBinaryExpressions (M.fromList [(TokenHelper.LESS, AST.LESS),
                                                        (TokenHelper.LESS_EQUAL, AST.LESS_EQUAL),
                                                        (TokenHelper.GREATER, AST.GREATER),
                                                        (TokenHelper.GREATER_EQUAL, AST.GREATER_EQUAL)]) createComparison createTerm

createTerm :: S.Seq Token -> EXPRESSION
createTerm = createBinaryExpressions (M.fromList [(TokenHelper.PLUS, AST.PLUS), 
                                                  (TokenHelper.MINUS, AST.MINUS)]) createTerm createFactor

createFactor :: S.Seq Token -> EXPRESSION
createFactor = createBinaryExpressions (M.fromList [(TokenHelper.SLASH, AST.SLASH), 
                                                    (TokenHelper.STAR, AST.STAR)]) createFactor createUnary

    
createUnary :: S.Seq Token -> EXPRESSION
createUnary tokens
  | isUnary = EXP_UNARY (UNARY getOp (createUnary (S.drop 1 tokens))) tokens
  | otherwise = createLiteral tokens
  where token = S.lookup 0 tokens
        tType = tokenType <$> token
        isUnary = tType == Just TokenHelper.BANG || tType == Just TokenHelper.MINUS
        getOp 
          | tType == Just TokenHelper.BANG = AST.BANG
          | tType == Just TokenHelper.MINUS = AST.MINUS
  
createLiteral :: S.Seq Token -> EXPRESSION
createLiteral tokens = checkLiteralToken token tokens
  where token = tokenType (S.index tokens 0)

checkLiteralToken :: TokenType -> S.Seq Token -> EXPRESSION
checkLiteralToken (TokenHelper.STRING a) _ = EXP_LITERAL (AST.STRING a)
checkLiteralToken (TokenHelper.NUMBER a) _  = EXP_LITERAL (AST.NUMBER a)
checkLiteralToken TokenHelper.FALSE _  = EXP_LITERAL AST.FALSE
checkLiteralToken TokenHelper.TRUE _  = EXP_LITERAL AST.TRUE
checkLiteralToken TokenHelper.NIL _ = EXP_LITERAL AST.NIL
checkLiteralToken (TokenHelper.IDENTIFIER a) tokens = EXP_LITERAL (AST.IDENTIFIER a tokens)
checkLiteralToken TokenHelper.LEFT_PAREN tokens
  | isEof = NON_EXP "Parenthesis not closed" tokens
  | isEmpty = NON_EXP "Empty parenthesis" tokens
  | otherwise = EXP_GROUPING (GROUP (createExpression tokensToUse))
  where tokensToMatch = S.takeWhileL (not . tokenIsType RIGHT_PAREN) tokens
        tokensToUse = S.drop 1 tokensToMatch
        eofFind = S.findIndexR (tokenIsType SEMICOLON) tokensToMatch
        isEof = getIsAnyEOF eofFind
        isEmpty = S.null tokensToUse
checkLiteralToken _ tokens = NON_EXP "Misplaced Token" tokens


--Helpers
findFromIndex :: Int -> (a -> Bool) -> S.Seq a -> Maybe Int
findFromIndex start predi tokens = S.findIndexL predi (S.drop start tokens) 

getIsAnyEOF :: Maybe Int -> Bool
getIsAnyEOF (Just _) = True
getIsAnyEOF Nothing = False

createBinaryExpressions :: M.Map TokenType OPERATOR -> (S.Seq Token -> EXPRESSION) -> (S.Seq Token -> EXPRESSION) -> S.Seq Token -> EXPRESSION
createBinaryExpressions tokenExpMap thisPrec nextPrec tokens = handleBinaryCases
  where
    indexOfOp = S.findIndexL (\x -> tokenType x `elem` M.keys tokenExpMap) tokens
    bin = prepBinary getOp (fromJust indexOfOp) tokens thisPrec nextPrec
    getOp indx = tokenExpMap M.! token
      where token = tokenType (S.index tokens indx)
    handleBinaryCases
      | isJust indexOfOp && indexOfOp > Just 0 = EXP_BINARY bin tokens
      | indexOfOp > Just (S.length tokens - 2) = NON_EXP "Missing operands from right side" tokens
      | otherwise = nextPrec tokens

prepBinary :: (Int -> OPERATOR) -> Int -> S.Seq Token -> (S.Seq Token -> EXPRESSION) -> (S.Seq Token -> EXPRESSION) -> BINARY
prepBinary getOperation idx tokens thisPrec nextPrec = AST.BIN (nextPrec left) op (thisPrec right)
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

isIdentifier :: TokenType -> Bool
isIdentifier (TokenHelper.IDENTIFIER _) = True
isIdentifier _ = False