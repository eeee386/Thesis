module Lexer where

import qualified Data.Text as T
import Data.Char

type TextType = T.Text

-- Maybe in the future I will use EOF and NOT_TOKEN -> NOT_TOKEN as an error type
data Token =  LEFT_PAREN | RIGHT_PAREN | LEFT_BRACE | RIGHT_BRACE |
                       COMMA | DOT | MINUS | PLUS | SEMICOLON | SLASH | STAR |

                       BANG | BANG_EQUAL |
                       EQUAL | EQUAL_EQUAL |
                       GREATER | GREATER_EQUAL |
                       LESS | LESS_EQUAL |

                       QUESTION_MARK | COLON |

                       IDENTIFIER TextType | STRING TextType | NUMBER Double |

                       AND | CLASS | ELSE | FALSE | FUN | FOR | IF | NIL | OR |
                       PRINT | RETURN | SUPER | THIS | TRUE | VAR | WHILE | BREAK | CONTINUE |

                       EOF | NOT_TOKEN TextType deriving (Show, Eq, Ord)

lexer :: String -> [Token]
lexer (c:cs)
      | isSpace c = lexer cs
      | isAlpha c = lexKeyword (c:cs)
      | isDigit c = lexNum (c:cs)
lexer ('=':cs) = lexHandleEqual cs
lexer ('!':cs) = lexHandleBang cs
lexer ('+':cs) = PLUS : lexer cs
lexer ('-':cs) = MINUS : lexer cs
lexer ('*':cs) = STAR : lexer cs
lexer ('/':cs) = lexHandleSlash cs
lexer ('(':cs) = LEFT_PAREN : lexer cs
lexer (')':cs) = RIGHT_PAREN : lexer cs
lexer ('{':cs) = LEFT_BRACE : lexer cs
lexer ('}':cs) = RIGHT_BRACE : lexer cs
lexer ('<': cs) = lexHandleLess cs
lexer ('>': cs) = lexHandleGreater cs
lexer (';': cs) = SEMICOLON : lexer cs
lexer (':': cs) = COLON : lexer cs
lexer ('.': cs) = DOT : lexer cs
lexer (',': cs) = COMMA : lexer cs
lexer ('\"': cs) = lexString cs
lexer (_:cs) = lexer cs
lexer [] = []

lexNum :: String -> [Token]
lexNum cs = NUMBER (read num) : lexer rest
      where (num,rest) = span isDigit cs

lexKeyword :: String -> [Token]
lexKeyword cs =
   case span (\x -> isAlpha x || isDigit x) cs of
      ("var",rest) -> VAR : lexer rest
      ("true", rest) -> TRUE : lexer rest
      ("false", rest) -> FALSE : lexer rest
      ("nil", rest) -> NIL : lexer rest
      ("and", rest) -> AND : lexer rest
      ("or", rest) -> OR : lexer rest
      ("print", rest) -> PRINT : lexer rest
      ("if", rest) -> IF : lexer rest
      ("else", rest) -> ELSE : lexer rest
      ("while", rest) -> WHILE : lexer rest
      ("for", rest) -> FOR : lexer rest
      ("fun", rest) -> FUN : lexer rest
      ("return", rest) -> RETURN : lexer rest
      ("class", rest) -> CLASS : lexer rest
      ("this", rest) -> THIS : lexer rest
      ("super", rest) -> SUPER : lexer rest
      ("break", rest) -> BREAK : lexer rest
      ("continue", rest) -> CONTINUE : lexer rest
      (var,rest)   -> IDENTIFIER (T.pack var) : lexer rest

lexString :: String -> [Token]
lexString cs = STRING (T.pack str) : lexer rest
  where (str, restWithQuoteSign) = span (/= '\"') cs
        (_:rest) = restWithQuoteSign

lexHandleEqual :: String -> [Token]
lexHandleEqual [] = [EQUAL]
lexHandleEqual (c:cs) = if c == '=' then EQUAL_EQUAL : lexer cs else EQUAL : lexer (c:cs)

lexHandleBang :: String -> [Token]
lexHandleBang [] = [BANG]
lexHandleBang (c:cs) = if c == '=' then BANG_EQUAL : lexer cs else BANG : lexer (c:cs)

lexHandleLess :: String -> [Token]
lexHandleLess [] = [LESS]
lexHandleLess (c:cs) = if c == '=' then LESS_EQUAL : lexer cs else LESS : lexer (c:cs)

lexHandleGreater :: String -> [Token]
lexHandleGreater [] = [GREATER]
lexHandleGreater (c:cs) = if c == '=' then GREATER_EQUAL : lexer cs else GREATER : lexer (c:cs)

lexHandleSlash :: String -> [Token]
lexHandleSlash [] = [SLASH]
lexHandleSlash (c:cs)
  | c == '/' = lexer afterCommentCs
  | c == '*' = lexer afterBlockCommentCs 
  | otherwise =  SLASH : lexer (c:cs)
  where afterCommentCs = drop 1 (dropWhile (/= '\n') cs)
        afterBlockComments = findEndOfBlockComment cs


-- IMPROVE: Could be a more elegant solution to the error
findEndOfBlockComment :: String -> String
findEndOfBlockComment ('*':'/':cs) = cs
findEndOfBlockComment (_:cs) = findEndOfBlockComment cs
findEndOfBlockComment [] = error "Block comment is not closed"
