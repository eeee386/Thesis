{-# LANGUAGE OverloadedStrings #-}
module ParseExpressions where
  
import qualified Data.Sequence as S
import TokenHelper
import AST
import qualified Data.Map as M
import Utils
import Data.Maybe

createExpression :: S.Seq Token -> EXPRESSION
createExpression = fst . createTernary

-- Other cases could be covered, such one of the operators missing
-- Could be problematic if we had used question marks and colons as other operands

createTernary :: S.Seq Token -> (EXPRESSION, S.Seq Token)
createTernary tokens
  | S.null firstRest || S.null secondRest || isQM || isC  = (NON_EXP "Not a valid ternary operator" tokens, tokens)
  | otherwise = ((EXP_TERNARY (TERN firstExpr op1 secondExpr op2 thirdExpr) tokens), tokens)
  where (firstExpr, firstRest) = createLogic tokens
        maybeOp1 = S.lookup 0 firstRest
        isQM = (tokenIsType TokenHelper.QUESTION_MARK  <$> maybeOp1) == Just True
        op1 = getOp (fromJust maybeOp1)
        (secondExpr, secondRest) = createLogic firstRest
        maybeOp2 = S.lookup 0 secondRest
        isC = (tokenIsType TokenHelper.COLON <$> maybeOp2) == Just True
        op2 = getOp (fromJust maybeOp2)
        (thirdExpr, thirdRest) = createLogic secondRest
        getOp token
          | tokenType token == TokenHelper.QUESTION_MARK = AST.QUESTION_MARK 
          | tokenType token == TokenHelper.COLON = AST.COLON



createLogic :: S.Seq Token -> (EXPRESSION, S.Seq Token)
createLogic = createBinaryExpressions (M.fromList [(TokenHelper.AND, AST.AND), 
                                                   (TokenHelper.OR, AST.OR)]) createLogic createEquality

createEquality :: S.Seq Token -> (EXPRESSION, S.Seq Token)
createEquality = createBinaryExpressions (M.fromList [(TokenHelper.EQUAL_EQUAL, AST.EQUAL_EQUAL), 
                                                      (TokenHelper.BANG_EQUAL, AST.BANG_EQUAL)]) createEquality createComparison

createComparison :: S.Seq Token -> (EXPRESSION, S.Seq Token)
createComparison = createBinaryExpressions (M.fromList [(TokenHelper.LESS, AST.LESS),
                                                        (TokenHelper.LESS_EQUAL, AST.LESS_EQUAL),
                                                        (TokenHelper.GREATER, AST.GREATER),
                                                        (TokenHelper.GREATER_EQUAL, AST.GREATER_EQUAL)]) createComparison createTerm

createTerm :: S.Seq Token -> (EXPRESSION, S.Seq Token)
createTerm = createBinaryExpressions (M.fromList [(TokenHelper.PLUS, AST.PLUS), 
                                                  (TokenHelper.MINUS, AST.MINUS)]) createTerm createFactor

createFactor :: S.Seq Token -> (EXPRESSION, S.Seq Token)
createFactor = createBinaryExpressions (M.fromList [(TokenHelper.SLASH, AST.SLASH), 
                                                    (TokenHelper.STAR, AST.STAR)]) createFactor createUnary


createUnary :: S.Seq Token -> (EXPRESSION, S.Seq Token)
createUnary tokens
  | isUnary = (EXP_UNARY (UNARY getOp (createUnary (S.drop 1 tokens))) tokens)
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


-- Not sure about synchronize
createBinaryExpressions :: M.Map TokenType OPERATOR -> (S.Seq Token -> (EXPRESSION, S.Seq Token)) -> (S.Seq Token -> (EXPRESSION, S.Seq Token)) -> S.Seq Token -> (EXPRESSION, S.Seq Token)
createBinaryExpressions tokenExpMap thisPrec nextPrec tokens
  | S.null firstRest = (firstExpr, firstRest)
  | isJust maybeOp =((EXP_BINARY (BIN firstExpr op secondExpr) tokens), secondRest)
  | otherwise = ((NON_EXP "Not a valid expression" tokens), snd (synchronize tokens))
  where (firstExpr, firstRest) = nextPrec tokens
        maybeOp = M.lookup (tokenType $ S.index firstRest 0) tokenExpMap
        op = fromJust maybeOp
        (secondExpr, secondRest) = thisPrec tokens

chainCall :: S.Seq Token -> CALL -> EXPRESSION
chainCall tokens (CALL_FUNC iden callArgs)
  | S.null tokens || isSemicolon = EXP_CALL (CALL_FUNC iden callArgs)
  | not isCall = NON_EXP "Invalid character in call" tokens
  | not hasRightParen = NON_EXP "Missing right parenthesis from chain function call" tokens
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

getMaybeOpFromMap :: S.Seq Token ->  M.Map TokenType OPERATOR -> Maybe OPERATOR
getMaybeOpFromMap firstRest  = M.lookup (tokenType $ S.index firstRest 0)

synchronize :: S.Seq Token -> (S.Seq Token, S.Seq Token)
synchronize tokens = if isJust maybeIndex then S.splitAt (fromJust maybeIndex) tokens else (tokens, S.empty)
  where syncFunc = S.findIndexL (\x -> tokenType x `elem` [CLASS, FUN, VAR, FOR, IF, WHILE, PRINT, TokenHelper.RETURN])
        startIndex = syncFunc tokens
        maybeIndex = if startIndex == Just 0 then syncFunc (S.drop 1 tokens) else startIndex
