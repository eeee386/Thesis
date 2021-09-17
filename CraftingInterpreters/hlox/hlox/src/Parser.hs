{-# LANGUAGE OverloadedStrings #-}

module Parser where

import AST
import qualified Data.Sequence as S
import TokenHelper
import Data.Maybe
import Utils
import ParseExpressions
import ParserTypes

-- Parser will add the id to the declarations, and the Resolver will add the ids to the expressions


parse :: S.Seq Token -> PROGRAM
parse = createProgram

createProgram :: S.Seq Token -> PROGRAM
createProgram tokens = PROG (createDeclarations (createParserMeta tokens) S.empty)

createDeclarations :: ParserMeta -> S.Seq DECLARATION -> S.Seq DECLARATION
createDeclarations meta decSeq 
  | isLastParseError || S.null (tokensLeft meta) = S.drop 1 (decSeq S.|> dec)
  | otherwise = createDeclarations newMeta (decSeq S.|> dec)
  where isLastParseError = (isParseError <$> getLast decSeq) == Just True
        newMeta = createDeclaration meta
        dec = declaration meta
        
createDeclaration :: ParserMeta -> ParserMeta
createDeclaration meta
  | isIf = handleIf meta
  | isWhile = handleWhile meta
  | isFor = handleFor meta
  | isFunction = handleFunction meta
  | isReturn = handleReturn meta
  | isBlockDec = handleBlock meta
  | otherwise = handleSimpleDeclaration meta
  where firstToken = S.lookup 0 (tokensLeft meta)
        firstTokenType = tokenType <$> firstToken
        isIf = firstTokenType == Just IF
        isBlockDec = firstTokenType == Just LEFT_BRACE
        isWhile = firstTokenType == Just WHILE
        isFor = firstTokenType == Just FOR
        isFunction = firstTokenType == Just FUN
        isReturn = firstTokenType == Just TokenHelper.RETURN


handleBlock :: ParserMeta -> ParserMeta
handleBlock meta
  | isClosed = updateDecAndTokens (DEC_STMT (BLOCK_STMT (createDeclarations (updateTokens innerDecTokens meta) S.empty))) right meta
  | otherwise = updateDecAndTokens (PARSE_ERROR "Block is not closed" tokens) right meta
  where tokens = tokensLeft meta
        index = findMatchingBraceIndex tokens
        isClosed = isJust index
        (left, right) = if isJust index then S.splitAt (fromJust index+1) tokens else synchronize tokens
        innerDecTokens = S.drop 1 (S.take (fromJust index) left)

handleSimpleDeclaration :: ParserMeta -> ParserMeta
handleSimpleDeclaration meta
  | isNothing index = updateDecAndTokens (PARSE_ERROR "Statement is not terminated" expr) rest meta
  | otherwise = updateParserMeta dec rest newId meta
  where tokens = tokensLeft meta
        index = S.findIndexL (tokenIsType SEMICOLON) tokens
        isTerminated = isJust index
        (expr, rest) = if isTerminated then S.splitAt (fromJust index+1) tokens else synchronize tokens
        (dec, newId) = buildSimpleDecFromTokens expr (currentVarId meta)

buildSimpleDecFromTokens :: S.Seq Token -> Int -> (DECLARATION, Int)
buildSimpleDecFromTokens expr id
  | isAssignment || isVar = handleAssignmentOrDecDef isVar findAssignment firstTokenType expr id
  | isPrint =(DEC_STMT (PRINT_STMT (createExpression (S.drop 1 expr))), id) 
  | isExpressionStatement = ((DEC_STMT (EXPR_STMT (createExpression expr))), id)
  | otherwise = (PARSE_ERROR "Not a valid declaration or expression" expr, id)
  where firstToken = S.lookup 0 expr
        firstTokenType = tokenType <$> firstToken
        findAssignment = S.findIndexL (tokenIsType TokenHelper.EQUAL) expr
        isAssignment = isJust findAssignment
        isVar = firstTokenType == Just TokenHelper.VAR
        isPrint = firstTokenType == Just PRINT
        isExpressionStatement = firstTokenType /= Just VAR && firstTokenType /= Just PRINT && firstTokenType /= Just LEFT_BRACE


handleAssignmentOrDecDef :: Bool -> Maybe Int -> Maybe TokenType -> S.Seq Token -> Int -> (DECLARATION, Int)
handleAssignmentOrDecDef isVar findAssignment firstTokenType expr id
  | isDecDef = (DEC_VAR (VAR_DEC_DEF (fromJust lValue) (createExpression defExpr) expr (Id id)), newId)
  | isOnlyDec = (DEC_VAR (VAR_DEC (fromJust lValue) expr (Id id)), newId)
  | isRedef = (DEC_VAR (VAR_DEF (fromJust lValue) (createExpression redefExpr) expr NOT_READY), id)
  | otherwise = (PARSE_ERROR "Not a valid declaration" expr, id)
  where newId = id+1
        defExpr = S.drop 3 expr
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


handleIf :: ParserMeta -> ParserMeta
handleIf meta
  | not isLeftParen = updateDecAndTokens (PARSE_ERROR "Parenthesis should be after if" err) rest meta
  | not isRightParen = updateDecAndTokens (PARSE_ERROR "Parenthesis is not closed" err) rest meta
  | not isElseToo && isJust ifStmt = updateDecAndTokens (DEC_STMT (IF_STMT expr (fromJust ifStmt))) restToCheck meta
  | isElseToo && isJust ifStmt && isJust elseStmt = updateDecAndTokens  (DEC_STMT (IF_ELSE_STMT expr (fromJust ifStmt) (fromJust elseStmt))) moreRestToCheck meta
  | otherwise = updateDecAndTokens (PARSE_ERROR "Not a valid if statement" err) rest meta
  where tokens = tokensLeft meta
        maybeLeftParen = S.lookup 1 tokens
        isLeftParen = (tokenIsType LEFT_PAREN <$> maybeLeftParen) == Just True
        rightParenIndex = S.findIndexL (tokenIsType RIGHT_PAREN) tokens
        isRightParen = isJust rightParenIndex
        exprTokens = S.drop 2 (S.takeWhileL (not . tokenIsType RIGHT_PAREN) tokens)
        expr = createExpression exprTokens
        nextTokens = S.drop (fromJust rightParenIndex+1) tokens
        newPMD = createDeclaration (updateTokens nextTokens meta)
        ifDec = declaration newPMD
        restToCheck = tokensLeft newPMD
        ifStmt = getStmtFromDec ifDec
        isElseToo = (tokenType <$> S.lookup 0 restToCheck) == Just ELSE
        newPME = createDeclaration (updateTokens (S.drop 1 restToCheck) meta)
        elseDec = declaration newPME
        moreRestToCheck = tokensLeft newPME
        elseStmt = getStmtFromDec elseDec
        (err, rest) = synchronize tokens


handleWhile :: ParserMeta -> ParserMeta
handleWhile meta
  | not isLeftParen = updateDecAndTokens (PARSE_ERROR "Parenthesis should be after while" err) rest meta
  | not isRightParen = updateDecAndTokens (PARSE_ERROR "Parenthesis is not closed" err) rest meta
  | isJust whileStmt = updateDecAndTokens (DEC_STMT (WHILE_STMT expr (fromJust whileStmt))) restToCheck meta
  | otherwise = updateDecAndTokens (PARSE_ERROR "Not a valid while statement" err) rest meta
  where tokens = tokensLeft meta
        maybeLeftParen = S.lookup 1 tokens
        isLeftParen = (tokenIsType LEFT_PAREN <$> maybeLeftParen) == Just True
        rightParenIndex = S.findIndexL (tokenIsType RIGHT_PAREN) tokens
        isRightParen = isJust rightParenIndex
        exprTokens = S.drop 2 (S.takeWhileL (not . tokenIsType RIGHT_PAREN) tokens)
        expr = createExpression exprTokens
        nextTokens = S.drop (fromJust rightParenIndex+1) tokens
        newPM =  createDeclaration (updateTokens nextTokens meta)
        whileDec = declaration newPM
        restToCheck = tokensLeft newPM
        whileStmt = getStmtFromDec whileDec
        (err, rest) = synchronize tokens

handleFor :: ParserMeta -> ParserMeta
handleFor meta
  | not isLeftParen = updateDecAndTokens (PARSE_ERROR "Parenthesis should be after for" err) rest meta
  | isParseError firstDec = updateDecAndTokens firstDec firstDecRest meta
  | not isSecondSemicolon = updateDecAndTokens (PARSE_ERROR "Invalid parts in for loop" err) rest meta
  | not isRightParen = updateDecAndTokens (PARSE_ERROR "Parenthesis is not closed" err) rest meta
  | isJust forStmt = updateDecAndTokens (DEC_STMT (FOR_STMT firstDec secondExpression thirdDeclaration (fromJust forStmt) )) forRest meta
  | otherwise = updateDecAndTokens (PARSE_ERROR "Not a valid for statement" err) rest meta
  where tokens = tokensLeft meta
        maybeLeftParen = S.lookup 1 tokens
        isLeftParen = (tokenIsType LEFT_PAREN <$> maybeLeftParen) == Just True
        newPMS = handleSimpleDeclaration (updateTokens (S.drop 2 tokens) meta)
        firstDec = declaration newPMS
        firstDecRest = tokensLeft newPMS
        secondSemicolon = S.findIndexL (tokenIsType SEMICOLON) firstDecRest
        isSecondSemicolon = isJust secondSemicolon
        (secondTokens, secRest) = if isSecondSemicolon then S.splitAt (fromJust secondSemicolon+1) firstDecRest else synchronize tokens
        secondExpression = createExpression secondTokens
        maybeRightParen = S.findIndexL (tokenIsType RIGHT_PAREN) secRest
        isRightParen = isJust maybeRightParen
        (thirdTokens, thirdRest) = if isRightParen then S.splitAt (fromJust maybeRightParen) secRest else synchronize tokens
        (thirdDeclaration, newId) = buildSimpleDecFromTokens thirdTokens (currentVarId meta)
        newPMD = createDeclaration (updateTokens (S.drop 1 thirdRest) meta)
        forDec = declaration newPMD
        forRest = tokensLeft newPMD
        forStmt = getStmtFromDec forDec
        (err, rest) = synchronize tokens


handleFunction :: ParserMeta -> ParserMeta
handleFunction meta
  | not isIden = updateDecAndTokens (PARSE_ERROR "Identifier is missing after 'fun' keyword" err) rest meta
  | not isLeftParen = updateDecAndTokens (PARSE_ERROR "Parenthesis should be after function header" err) rest meta
  | not isRightParen = updateDecAndTokens (PARSE_ERROR "Parenthesis is not closed" err) rest meta
  | otherwise = updateParserMeta (DEC_FUNC (FUNC_DEC (fromJust maybeIdenType) params (FUNC_STMT (fromJust stmt))) (Id id)) funRest newId newPMF
  where id = currentVarId meta
        tokens = tokensLeft meta
        maybeIden = S.lookup 1 tokens
        maybeIdenType = tokenType <$>  maybeIden
        isIden = (isIdentifier <$> maybeIdenType) == Just True
        maybeLeftParen = S.lookup 2 tokens
        isLeftParen = (tokenType <$> maybeLeftParen) == Just LEFT_PAREN
        rightParenIndex = S.findIndexL (tokenIsType RIGHT_PAREN) (S.drop 3 tokens)
        isRightParen = isJust rightParenIndex
        paramTokens = S.drop 3 (S.takeWhileL (not . tokenIsType RIGHT_PAREN) tokens)
        (params, newId) = handleBuildParams paramTokens (id+1) (PARAMETERS S.empty paramTokens)
        stmtRest = S.drop 1 (S.dropWhileL (not . tokenIsType RIGHT_PAREN) tokens)
        newPMF = createDeclaration (updateTokens stmtRest meta)
        dec = declaration newPMF
        funRest = tokensLeft newPMF
        stmt = getStmtFromDec dec
        (err, rest) = synchronize tokens

handleBuildParams :: S.Seq Token -> Int -> PARAMETERS -> (PARAMETERS, Int)
handleBuildParams tokens id (PARAMETERS idens paramTokens)
 | S.null tokens = (PARAMETERS idens tokens, id)
 | S.null idenTokens = (INVALID_PARAMS "Empty parameter" paramTokens, id)
 | not isIden = (INVALID_PARAMS "Parameters can only be identifiers" paramTokens, id)
 | otherwise = handleBuildParams rest (id+1) (PARAMETERS (idens S.|> newIden) paramTokens)
 where idenTokens = S.takeWhileL (not . tokenIsType COMMA) tokens
       maybeIden = tokenType (S.index idenTokens 0)
       isIden = isIdentifier maybeIden
       newIden = (DEC_VAR (PARAM_DEC (S.index idenTokens 0) idenTokens id))
       rest = S.drop (S.length idenTokens+1) tokens


handleReturn :: ParserMeta -> ParserMeta
handleReturn meta
  | S.null exprTokens = updateDecAndTokens (DEC_STMT RETURN_NIL) (S.drop 2 tokens) meta
  | otherwise = updateDecAndTokens (DEC_STMT (AST.RETURN (createExpression exprTokens))) (S.drop 2 $ S.drop (S.length exprTokens+1) tokens) meta
  where tokens = tokensLeft meta
        exprTokens = S.drop 1 (S.takeWhileL (not . tokenIsType SEMICOLON) tokens)


getStmtFromDec :: DECLARATION -> Maybe STATEMENT
getStmtFromDec (DEC_STMT x) = Just x
getStmtFromDec _ = Nothing
