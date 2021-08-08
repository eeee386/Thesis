{-# LANGUAGE OverloadedStrings #-}

module Scanner where

import qualified Data.Text as T
import Data.Char
import TokenHelper
import qualified Data.Sequence as S
import qualified Text.Read as TR
import Data.Maybe

data TokenReader = TokenReader {
len :: Int
, token :: TokenType
, numberOfNewLines :: Int
} deriving Show

createToken :: TokenType -> Int -> Int -> TokenReader
createToken tType tLength tNewLines = TokenReader {token=tType, len=tLength, numberOfNewLines=tNewLines}
  
createNoNewLineToken :: TokenType -> Int -> TokenReader
createNoNewLineToken tType tLength = createToken tType tLength 0

createNewLine :: TokenReader
createNewLine = createToken WHITE_SPACE 1 1

checkIfTwoLengthToken :: T.Text -> T.Text -> TokenType -> TokenType -> TokenReader
checkIfTwoLengthToken textPart stringToken twoLengthToken oneLengthToken = if textPart == stringToken then createNoNewLineToken twoLengthToken 2 else createNoNewLineToken oneLengthToken 1

checkIfCommentOrDivision :: T.Text -> TokenReader
checkIfCommentOrDivision text
  | twoLengthStr == "//" = createNoNewLineToken COMMENT (T.length (head (T.lines text)))
  | twoLengthStr == "/*" = createBlockComment text
  | otherwise = createNoNewLineToken SLASH 1
  where twoLengthStr =  T.take 2 text
 
createBlockComment :: T.Text -> TokenReader 
createBlockComment = checkBlockComment 0 0
  where 
    checkBlockComment :: Int -> Int -> T.Text -> TokenReader
    checkBlockComment tl nl t
        | T.take 1 t == "" = createNoNewLineToken (NOT_TOKEN t) tl 
        | T.head t == '\n' = checkBlockComment (tl+1) (nl+1) (T.tail t)
        | T.take 2 t == "*/" = createToken BLOCK_COMMENT (tl+2) nl 
        | otherwise = checkBlockComment (tl+1) nl (T.tail t)

handleWhiteSpace :: TokenReader
handleWhiteSpace = createNoNewLineToken WHITE_SPACE 1

createString :: T.Text -> TokenReader 
createString text = if lengthOfTheNewString == lengthOfTheRest then createNoNewLineToken (NOT_TOKEN restOfTheText) lengthOfTheRest else createToken (STRING newString) (lengthOfTheNewString + 2) numberOfNL 
  where newString = T.takeWhile (/= '\"') restOfTheText
        restOfTheText = T.tail text
        lengthOfTheRest = T.length restOfTheText
        lengthOfTheNewString = T.length newString
        numberOfNL = T.foldl' (\y x -> if x == '\n' then y+1 else y) 0 newString 
        
createNumber :: T.Text -> TokenReader
createNumber text = if isJust number then createNoNewLineToken (NUMBER (fromJust number)) lengthOfTheNumber else createNoNewLineToken (NOT_TOKEN numberString) lengthOfTheNumber
  where numberString = T.takeWhile (\x -> isDigit x || x == '.') text
        lengthOfTheNumber = T.length numberString
        number = getNumberFromEither (TR.readEither (T.unpack numberString))

-- Should have used readMaybe, but the stack could not figure out the imports even with qualified TR import, when using TR.readMaybe
getNumberFromEither :: Either String Double -> Maybe Double
getNumberFromEither (Right a) = Just a
getNumberFromEither (Left _) = Nothing




createIdentifierChunk :: T.Text -> T.Text
createIdentifierChunk = T.takeWhile (\ x -> isAlpha x || isDigit x)

createKeyWord ::  TokenType -> TokenReader
createKeyWord tType = createNoNewLineToken tType tLen 
  where tokenString = map toLower (show tType)
        tLen = length tokenString

createIdentifier :: T.Text -> TokenReader
createIdentifier text
  | chunk == "and" = createKeyWord AND
  | chunk == "or" = createKeyWord OR
  | chunk == "if" = createKeyWord IF
  | chunk == "else" = createKeyWord ELSE
  | chunk == "class" = createKeyWord CLASS
  | chunk == "false" = createKeyWord FALSE
  | chunk == "fun" = createKeyWord FUN
  | chunk == "for" = createKeyWord FOR
  | chunk == "nil" = createKeyWord NIL
  | chunk == "print" = createKeyWord PRINT
  | chunk == "return" = createKeyWord RETURN
  | chunk == "super" = createKeyWord SUPER
  | chunk == "this" = createKeyWord THIS
  | chunk == "true" = createKeyWord TRUE
  | chunk == "var" = createKeyWord VAR
  | chunk == "while" = createKeyWord WHILE
  | otherwise = createNoNewLineToken (IDENTIFIER chunk) (T.length chunk)
  where chunk = createIdentifierChunk text



recognizeToken :: T.Text -> TokenReader
recognizeToken text
  | tok == ")" = createNoNewLineToken RIGHT_PAREN 1
  | tok == "(" = createNoNewLineToken LEFT_PAREN 1
  | tok == "}" = createNoNewLineToken RIGHT_BRACE 1
  | tok == "{" = createNoNewLineToken LEFT_BRACE 1
  | tok == "," = createNoNewLineToken COMMA 1
  | tok == "." = createNoNewLineToken DOT 1
  | tok == "-" = createNoNewLineToken MINUS 1
  | tok == "+" = createNoNewLineToken PLUS 1
  | tok == ";" = createNoNewLineToken SEMICOLON 1
  | tok == "*" = createNoNewLineToken STAR 1
  | tok == "?" = createNoNewLineToken QUESTION_MARK 1
  | tok == ":" = createNoNewLineToken COLON 1
  | tok == "!" = checkIfTwoLengthToken twoTok "!=" BANG_EQUAL BANG
  | tok == "=" = checkIfTwoLengthToken twoTok "==" EQUAL_EQUAL EQUAL
  | tok == "<" = checkIfTwoLengthToken twoTok "<=" LESS_EQUAL LESS
  | tok == ">" = checkIfTwoLengthToken twoTok ">=" GREATER_EQUAL GREATER
  | tok == "/" = checkIfCommentOrDivision text
  | tok == " " = handleWhiteSpace
  | tok == "/t" = handleWhiteSpace
  | tok == "/n" = createNewLine
  | tok == "\"" = createString text
  | isDigit (T.head tok) = createNumber text
  | isAlpha (T.head tok) = createIdentifier text
  --TODO: handle non-tokens gracefully
  | otherwise = createNoNewLineToken (NOT_TOKEN tok) 1
  where tok = T.take 1 text 
        twoTok = T.take 2 text 

scanTokens :: T.Text -> S.Seq Token
scanTokens src = (S.|>) (S.filter (\x -> tokenType x /= WHITE_SPACE && tokenType x /= COMMENT) (scanTokensWithData 0 1 S.empty src)) (Token {tokenType=EOF, line= length (T.lines src)})
  where
    isAtEnd current = current == T.length src
    scanTokensWithData :: Int -> Int -> S.Seq Token -> T.Text -> S.Seq Token
    scanTokensWithData current lineP list text =
          let tokenScanned = recognizeToken text
              lenP = len tokenScanned
              tokenP = Token {tokenType= token tokenScanned, line=lineP}
              numberOfNewLinesP = numberOfNewLines tokenScanned
              newCurrent = current + lenP
              newLineNumber = lineP + numberOfNewLinesP
          in
            if isAtEnd current then list else scanTokensWithData newCurrent newLineNumber ((S.|>) list tokenP) (T.drop lenP text)


isNotToken :: TokenType -> Bool
isNotToken (NOT_TOKEN _) = True
isNotToken _ = False