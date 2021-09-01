{-# LANGUAGE OverloadedStrings #-}
module ParseExpressions where
  
import qualified Data.Sequence as S
import TokenHelper
import AST
import qualified Data.Map as M
import Utils
import Data.Maybe

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


createLogic :: S.Seq Token -> EXPRESSION
createLogic = createBinaryExpressions (M.fromList [(TokenHelper.AND, AST.AND), 
                                                   (TokenHelper.OR, AST.OR)]) createLogic createEquality

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
  | otherwise = createCall tokens
  where token = S.lookup 0 tokens
        tType = tokenType <$> token
        isUnary = tType == Just TokenHelper.BANG || tType == Just TokenHelper.MINUS
        getOp
          | tType == Just TokenHelper.BANG = AST.BANG
          | tType == Just TokenHelper.MINUS = AST.MINUS


createCall :: S.Seq Token -> EXPRESSION
createCall tokens
  | not isIden || (isIden && not isCall) = createLiteral tokens
  | not hasRightParen = NON_EXP "Missing right parenthesis from function call" tokens
  | otherwise = chainCall rest (CALL_FUNC (createASTIdentifier tokens tIden) (S.singleton args))
  where maybeIden = S.lookup 0 tokens
        isIden = (isIdentifierToken <$> maybeIden) == Just True
        iden = fromJust maybeIden
        tIden = tokenType iden
        isCall = isIden && (tokenType <$> S.lookup 1 tokens) == Just LEFT_PAREN
        (hasRightParen, rest, args) = functionHelper False tokens


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
  | otherwise = createLogic tokens
  where tern = prepTernary getOp1 getOp2 (fromJust indexOfOp1) (fromJust indexOfOp2) tokens createLogic
        bothIsJust = isJust indexOfOp1 && isJust indexOfOp2
        xorIsJust = isJust indexOfOp1 /= isJust indexOfOp2
        properPlacement = ((-) <$> indexOfOp2 <*> indexOfOp1) > Just 1 && indexOfOp2 < Just (S.length tokens - 2)

chainCall :: S.Seq Token -> CALL -> EXPRESSION
chainCall tokens (CALL_FUNC iden callArgs)
  | S.null tokens || isSemicolon = EXP_CALL (CALL_FUNC iden callArgs)
  | not isCall = NON_EXP "Invalid character in call" tokens
  | not hasRightParen = NON_EXP "Missing right parenthesis from function call" tokens
  | otherwise = chainCall rest (CALL_FUNC iden (callArgs S.|> args))
  where isCall = (tokenType <$> S.lookup 0 tokens) == Just LEFT_PAREN
        isSemicolon = (tokenType <$> S.lookup 0 tokens) == Just SEMICOLON
        (hasRightParen, rest, args) = functionHelper True tokens

functionHelper :: Bool -> S.Seq Token -> (Bool, S.Seq Token, ARGUMENTS)
functionHelper isChain tokens = (hasRightParen, rest, args)
  where rightParentIndex = S.findIndexL (tokenIsType RIGHT_PAREN) tokens
        hasRightParen = isJust rightParentIndex
        dropNumber = if isChain then 1 else 2
        argsTokens = S.drop dropNumber (S.takeWhileL (not . tokenIsType RIGHT_PAREN) tokens)
        rest = S.drop 1 (S.dropWhileL (not . tokenIsType RIGHT_PAREN) tokens)
        args = buildArgs argsTokens S.empty

-- Should create a PARSE_WARNING type, when arguments are more than 255
buildArgs :: S.Seq Token -> S.Seq EXPRESSION -> ARGUMENTS
buildArgs tokens exprs
 | S.null tokens = ARGS exprs
 | S.null exprTokens = INVALID_ARGS "Empty argument" tokens
 | otherwise = buildArgs rest (exprs S.|> newExpr)
 where exprTokens = S.takeWhileL (not . tokenIsType COMMA) tokens
       newExpr = createExpression exprTokens
       rest = S.drop (S.length exprTokens+1) tokens

isIdentifier :: TokenType -> Bool
isIdentifier (TokenHelper.IDENTIFIER _) = True
isIdentifier _ = False

isIdentifierToken :: Token -> Bool
isIdentifierToken t = isIdentifier (tokenType t)

createASTIdentifier ::S.Seq Token ->  TokenType -> EXPRESSION
createASTIdentifier tokens (TokenHelper.IDENTIFIER a) = EXP_LITERAL (AST.IDENTIFIER a tokens)
