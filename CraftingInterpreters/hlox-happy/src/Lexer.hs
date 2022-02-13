module Lexer where

import qualified Data.Text as T
import Data.Char

type TextType = T.Text

data Token =  LEFT_PAREN | RIGHT_PAREN | LEFT_BRACE | RIGHT_BRACE |
                       COMMA | DOT | MINUS | PLUS | SEMICOLON | SLASH | STAR |

                       BANG | BANG_EQUAL |
                       EQUAL | EQUAL_EQUAL |
                       GREATER | GREATER_EQUAL |
                       LESS | LESS_EQUAL |

                       QUESTION_MARK | COLON |

                       IDENTIFIER TextType | STRING TextType | NUMBER Double |

                       AND | CLASS | ELSE | FALSE | FUN | FOR | IF | NIL | OR |
                       PRINT | RETURN | SUPER | THIS | TRUE | VAR | WHILE |

                       COMMENT | BLOCK_COMMENT | WHITE_SPACE |

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
lexer ('/':cs) = SLASH : lexer cs
lexer ('(':cs) = LEFT_PAREN : lexer cs
lexer (')':cs) = RIGHT_PAREN : lexer cs
lexer ('<': cs) = LESS : lexer cs
lexer ('>': cs) = GREATER : lexer cs
lexer (';': cs) = SEMICOLON : lexer cs
lexer (':': cs) = COLON : lexer cs
lexer ('.': cs) = DOT : lexer cs
lexer ('\"': cs) = lexString cs
lexer [] = []

lexNum :: String -> [Token]
lexNum cs = NUMBER (read num) : lexer rest
      where (num,rest) = span isDigit cs

lexKeyword :: String -> [Token]
lexKeyword cs =
   case span isAlpha cs of
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
      (var,rest)   -> IDENTIFIER (T.pack var) : lexer rest

lexString :: String -> [Token]
lexString cs = STRING (T.pack str) : lexer rest
  where (str, restWithQuoteSign) = span (/= '\"') cs
        (_:rest) = restWithQuoteSign

lexHandleEqual :: String -> [Token]
lexHandleEqual (c:cs) = if c == '=' then EQUAL_EQUAL : lexer cs else EQUAL : lexer (c:cs)

lexHandleBang :: String -> [Token]
lexHandleBang (c:cs) = if c == '=' then BANG_EQUAL : lexer cs else BANG : lexer (c:cs)
