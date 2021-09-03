{-# LANGUAGE OverloadedStrings #-}

module Parser where

import AST
import qualified Data.Sequence as S
import TokenHelper
import Data.Maybe
import Utils
import ParseExpressions

parse :: S.Seq Token -> PROGRAM
parse = createProgram

createProgram :: S.Seq Token -> PROGRAM
createProgram tokens = PROG (createDeclarations tokens S.empty)

createDeclarations :: S.Seq Token -> S.Seq DECLARATION -> S.Seq DECLARATION
createDeclarations tokens decSeq 
  | isLastParseError || S.null tokens = decSeq
  | otherwise = createDeclarations rest (decSeq S.|> dec)
  where isLastParseError = (isParseError <$> getLast decSeq) == Just True
        (dec, rest) = createDeclaration tokens
        
createDeclaration :: S.Seq Token -> (DECLARATION, S.Seq Token)
createDeclaration tokens
  | isIf = handleIf tokens
  | isWhile = handleWhile tokens
  | isFor = handleFor tokens
  | isFunction = handleFunction tokens
  | isReturn = handleReturn tokens
  | isBlockDec = handleBlock tokens
  | otherwise = handleSimpleDeclaration tokens
  where firstToken = S.lookup 0 tokens
        firstTokenType = tokenType <$> firstToken
        isIf = firstTokenType == Just IF
        isBlockDec = firstTokenType == Just LEFT_BRACE
        isWhile = firstTokenType == Just WHILE
        isFor = firstTokenType == Just FOR
        isFunction = firstTokenType == Just FUN
        isReturn = firstTokenType == Just TokenHelper.RETURN
  

handleBlock :: S.Seq Token -> (DECLARATION, S.Seq Token)
handleBlock tokens
  | isClosed = (DEC_STMT (BLOCK_STMT (createDeclarations innerDecTokens S.empty)), right)
  | otherwise = (PARSE_ERROR "Block is not closed" tokens, right)
  where index = findMatchingBraceIndex tokens
        isClosed = isJust index
        (left, right) = if isJust index then S.splitAt (fromJust index+1) tokens else synchronize tokens
        innerDecTokens = S.drop 1 (S.take (fromJust index) left)

handleSimpleDeclaration :: S.Seq Token -> (DECLARATION, S.Seq Token)
handleSimpleDeclaration tokens 
  | isNothing index = (PARSE_ERROR "Statement is not terminated" expr, rest)
  | otherwise = (buildSimpleDecFromTokens expr, rest)
  where index = S.findIndexL (tokenIsType SEMICOLON) tokens
        isTerminated = isJust index
        (expr, rest) = if isTerminated then S.splitAt (fromJust index+1) tokens else synchronize tokens
        
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
  | not isLeftParen = (PARSE_ERROR "Parenthesis should be after if" err, rest)
  | not isRightParen = (PARSE_ERROR "Parenthesis is not closed" err, rest)
  | not isElseToo && isJust ifStmt = (DEC_STMT (IF_STMT expr (fromJust ifStmt)), restToCheck)
  | isElseToo && isJust ifStmt && isJust elseStmt = (DEC_STMT (IF_ELSE_STMT expr (fromJust ifStmt) (fromJust elseStmt)), moreRestToCheck)
  | otherwise = (PARSE_ERROR "Not a valid if statement" err, rest)
  where maybeLeftParen = S.lookup 1 tokens
        isLeftParen = (tokenIsType LEFT_PAREN <$> maybeLeftParen) == Just True
        rightParenIndex = S.findIndexL (tokenIsType RIGHT_PAREN) tokens
        isRightParen = isJust rightParenIndex
        exprTokens = S.drop 2 (S.takeWhileL (not . tokenIsType RIGHT_PAREN) tokens)
        expr = createExpression exprTokens
        nextTokens = S.drop (fromJust rightParenIndex+1) tokens
        (ifDec, restToCheck) = createDeclaration nextTokens
        ifStmt = getStmtFromDec ifDec
        isElseToo = (tokenType <$> S.lookup 0 restToCheck) == Just ELSE
        (elseDec, moreRestToCheck) = createDeclaration (S.drop 1 restToCheck)
        elseStmt = getStmtFromDec elseDec
        (err, rest) = synchronize tokens


handleWhile :: S.Seq Token -> (DECLARATION, S.Seq Token)
handleWhile tokens
  | not isLeftParen = (PARSE_ERROR "Parenthesis should be after while" err, rest)
  | not isRightParen = (PARSE_ERROR "Parenthesis is not closed" err, rest)
  | isJust whileStmt = (DEC_STMT (WHILE_STMT expr (fromJust whileStmt)), restToCheck)
  | otherwise = (PARSE_ERROR "Not a valid while statement" err, rest)
  where maybeLeftParen = S.lookup 1 tokens
        isLeftParen = (tokenIsType LEFT_PAREN <$> maybeLeftParen) == Just True
        rightParenIndex = S.findIndexL (tokenIsType RIGHT_PAREN) tokens
        isRightParen = isJust rightParenIndex
        exprTokens = S.drop 2 (S.takeWhileL (not . tokenIsType RIGHT_PAREN) tokens)
        expr = createExpression exprTokens
        nextTokens = S.drop (fromJust rightParenIndex+1) tokens
        (whileDec, restToCheck) = createDeclaration nextTokens
        whileStmt = getStmtFromDec whileDec
        (err, rest) = synchronize tokens

handleFor :: S.Seq Token -> (DECLARATION, S.Seq Token)
handleFor tokens
  | not isLeftParen = (PARSE_ERROR "Parenthesis should be after for" err, rest)
  | isParseError firstDec = (firstDec, firstDecRest)
  | not isSecondSemicolon = (PARSE_ERROR "Invalid parts in for loop" err, rest)
  | not isRightParen = (PARSE_ERROR "Parenthesis is not closed" err, rest)
  | isJust forStmt = (DEC_STMT (FOR_STMT firstDec secondExpression thirdDeclaration (fromJust forStmt) ),forRest)
  | otherwise = (PARSE_ERROR "Not a valid for statement" err, rest)
  where maybeLeftParen = S.lookup 1 tokens
        isLeftParen = (tokenIsType LEFT_PAREN <$> maybeLeftParen) == Just True
        (firstDec, firstDecRest) = handleSimpleDeclaration (S.drop 2 tokens)
        secondSemicolon = S.findIndexL (tokenIsType SEMICOLON) firstDecRest
        isSecondSemicolon = isJust secondSemicolon
        (secondTokens, secRest) = if isSecondSemicolon then S.splitAt (fromJust secondSemicolon+1) firstDecRest else synchronize tokens
        secondExpression = createExpression secondTokens
        maybeRightParen = S.findIndexL (tokenIsType RIGHT_PAREN) secRest
        isRightParen = isJust maybeRightParen
        (thirdTokens, thirdRest) = if isRightParen then S.splitAt (fromJust maybeRightParen) secRest else synchronize tokens
        thirdDeclaration = buildSimpleDecFromTokens thirdTokens
        (forDec, forRest) = createDeclaration (S.drop 1 thirdRest)
        forStmt = getStmtFromDec forDec
        (err, rest) = synchronize tokens


handleFunction :: S.Seq Token -> (DECLARATION, S.Seq Token)
handleFunction tokens
  | not isIden = (PARSE_ERROR "Identifier is missing after 'fun' keyword" err, rest)
  | not isLeftParen = (PARSE_ERROR "Parenthesis should be after function header" err, rest)
  | not isRightParen = (PARSE_ERROR "Parenthesis is not closed" err, rest)
  | otherwise = (DEC_FUNC (FUNC_DEC (fromJust maybeIdenType) params (FUNC_STMT (fromJust stmt))), funRest)
  where maybeIden = S.lookup 1 tokens
        maybeIdenType = tokenType <$>  maybeIden
        isIden = (isIdentifier <$> maybeIdenType) == Just True
        maybeLeftParen = S.lookup 2 tokens
        isLeftParen = (tokenType <$> maybeLeftParen) == Just LEFT_PAREN
        rightParenIndex = S.findIndexL (tokenIsType RIGHT_PAREN) (S.drop 3 tokens)
        isRightParen = isJust rightParenIndex
        paramTokens = S.drop 3 (S.takeWhileL (not . tokenIsType RIGHT_PAREN) tokens)
        params = handleBuildParams paramTokens (PARAMETERS S.empty)
        stmtRest = S.drop 1 (S.dropWhileL (not . tokenIsType RIGHT_PAREN) tokens)
        (dec, funRest) = createDeclaration stmtRest
        stmt = getStmtFromDec dec
        (err, rest) = synchronize tokens

handleBuildParams :: S.Seq Token -> PARAMETERS -> PARAMETERS
handleBuildParams tokens (PARAMETERS idens)
 | S.null tokens = PARAMETERS idens
 | S.null idenTokens = INVALID_PARAMS "Empty parameter" tokens
 | (not . isExpLiteralIdentifier) newIden = INVALID_PARAMS "Parameters can only be identifiers" tokens
 | otherwise = handleBuildParams rest (PARAMETERS (idens S.|> newIden))
 where idenTokens = S.takeWhileL (not . tokenIsType COMMA) tokens
       newIden = createExpression idenTokens
       rest = S.drop (S.length idenTokens+1) tokens


handleReturn :: S.Seq Token -> (DECLARATION, S.Seq Token)
handleReturn tokens
  | S.null exprTokens = (DEC_STMT RETURN_NIL, S.drop 2 tokens)
  | otherwise = (DEC_STMT (AST.RETURN (createExpression exprTokens)),S.drop 2 $ S.drop (S.length exprTokens+1) tokens)
  where exprTokens = S.drop 1 (S.takeWhileL (not . tokenIsType SEMICOLON) tokens)


getStmtFromDec :: DECLARATION -> Maybe STATEMENT
getStmtFromDec (DEC_STMT x) = Just x
getStmtFromDec _ = Nothing
