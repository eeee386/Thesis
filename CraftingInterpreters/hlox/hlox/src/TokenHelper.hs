{-# LANGUAGE OverloadedStrings #-}



module TokenHelper where

import qualified Data.Text as T
  
type TextType = T.Text
  
data TokenType =     LEFT_PAREN | RIGHT_PAREN | LEFT_BRACE | RIGHT_BRACE |
                     COMMA | DOT | MINUS | PLUS | SEMICOLON | SLASH | STAR |
                 
                     BANG | BANG_EQUAL |
                     EQUAL | EQUAL_EQUAL |
                     GREATER | GREATER_EQUAL |
                     LESS | LESS_EQUAL |
                 
                     IDENTIFIER TextType | STRING TextType | NUMBER Float |
                 
                     AND | CLASS | ELSE | FALSE | FUN | FOR | IF | NIL | OR |
                     PRINT | RETURN | SUPER | THIS | TRUE | VAR | WHILE |
                     
                     COMMENT | BLOCK_COMMENT | WHITE_SPACE | 
                 
                     EOF | NOT_TOKEN deriving (Show, Eq)

data Literal = LiteralString TextType | LiteralNumber Float | LiteralBool Bool | LiteralOther deriving Show
                  
                     
data Token = Token {
tokenType :: TokenType
, lexeme :: T.Text
, literal :: Literal
, line :: Int
} 

instance Show Token where
  show a = mconcat ["{", show (tokenType a), ", ", T.unpack (lexeme a), ", ", show (literal a), ", ", show (line a), "}"]
