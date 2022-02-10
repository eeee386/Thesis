{
module HappyParser where

import Data.Char
import AST
import Lexer as L
}

%name calc
%tokentype { Token }
%error { parseError }

%left 'and' 'or'
%left '==' '!='
%left '>' '<' '<=' '>='
%left '+' '-'
%left '*' '/'
%right UN

%token
      NUMBER          { L.NUMBER $$ }
      STRING          { L.STRING $$ }
      '='             { L.EQUAL }
      '+'             { L.PLUS }
      '-'             { L.MINUS }
      '*'             { L.STAR }
      '/'             { L.SLASH }
      '('             { L.LEFT_PAREN }
      ')'             { L.RIGHT_PAREN }
      '!'             { L.BANG }
      '<'             { L.LESS }
      '>'             { L.GREATER }
      '<='            { L.LESS_EQUAL }
      '>='            { L.GREATER_EQUAL }
      '!='            { L.BANG_EQUAL }
      '=='            { L.EQUAL_EQUAL }
      'and'           { L.AND }
      'or'            { L.OR }
      'true'          { L.TRUE }
      'false'         { L.FALSE }
      'nil'           { L.NIL }

%%

expression     : literal        {EXP_LITERAL $1}
               | unary          {EXP_UNARY $1}
               | binary         {EXP_BINARY $1}
               | grouping       {EXP_GROUPING $1}

literal        : NUMBER         {AST.NUMBER $1}
               | STRING         {AST.STRING $1}
               | 'true'         {AST.TRUE}
               | 'false'        {AST.FALSE}
               | 'nil'          {AST.NIL}

grouping       : '(' expression ')'                  {GROUP $2}
unary          : '-' expression %prec UN         {UNARY_MINUS $2}
               | '!' expression %prec UN         {UNARY_NEGATE $2}
binary         : expression '==' expression      {BIN_EQ $1 $3}
               | expression '!=' expression      {BIN_NOT_EQ $1 $3}
               | expression '+' expression      {BIN_ADD $1 $3}
               | expression '-' expression      {BIN_SUB $1 $3}
               | expression '*' expression      {BIN_MUL $1 $3}
               | expression '/' expression      {BIN_DIV $1 $3}
               | expression '>' expression      {BIN_COMP_GREATER $1 $3}
               | expression '<' expression      {BIN_COMP_LESS $1 $3}
               | expression '>=' expression      {BIN_COMP_GREATER_EQ $1 $3}
               | expression '<=' expression      {BIN_COMP_LESS_EQ $1 $3}
               | expression 'and' expression     {BIN_AND $1 $3}
               | expression 'or' expression      {BIN_OR $1 $3}

{
parseError :: [Token] -> a
parseError _ = error "Parse error"


happyParser = calc . lexer

}