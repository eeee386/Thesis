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
                     
                     QUESTION_MARK | COLON |
                 
                     IDENTIFIER TextType | STRING TextType | NUMBER Double |
                 
                     AND | CLASS | ELSE | FALSE | FUN | FOR | IF | NIL | OR |
                     PRINT | RETURN | SUPER | THIS | TRUE | VAR | WHILE |
                     
                     COMMENT | BLOCK_COMMENT | WHITE_SPACE | 
                 
                     EOF | NOT_TOKEN TextType deriving (Show, Eq, Ord)             
                     
data Token = Token {
tokenType :: TokenType
, line :: Int
} deriving Eq

instance Show Token where
  show a = mconcat ["{", show (tokenType a), ", ", show (line a), "}"]
