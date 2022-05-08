{
module Generated.HappyParser where

import Data.Char
import AST
import Lexer as L
}

%name parser
%tokentype { Token }
%error { parseError }

%right '='
%nonassoc '?' ':'
%left 'and' 'or'
%left '==' '!='
%left '>' '<' '<=' '>='
%left '+' '-'
%left '*' '/'
%right UN
%nonassoc call

%token
      NUMBER          { L.NUMBER $$ }
      STRING          { L.STRING $$ }
      IDENTIFIER      { L.IDENTIFIER $$ }
      '='             { L.EQUAL }
      '+'             { L.PLUS }
      '-'             { L.MINUS }
      '*'             { L.STAR }
      '/'             { L.SLASH }
      '('             { L.LEFT_PAREN }
      ')'             { L.RIGHT_PAREN }
      '{'             { L.LEFT_BRACE }
      '}'             { L.RIGHT_BRACE }
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
      ';'             { L.SEMICOLON }
      ','             { L.COMMA }
      '?'             { L.QUESTION_MARK }
      ':'             { L.COLON }
      '.'             { L.DOT }
      'print'         { L.PRINT }
      'var'           { L.VAR }
      'if'            { L.IF }
      'else'          { L.ELSE }
      'while'         { L.WHILE }
      'for'           { L.FOR }
      'fun'           { L.FUN }
      'return'        { L.RETURN }
      'class'         { L.CLASS }
      'this'          { L.THIS }
      'super'         { L.SUPER }
      'continue'      { L.CONTINUE }
      'break'         { L.BREAK }

%%

program        : declarations                 { PROG (reverse $1) }

declarations   : declarations declaration     { $2 : $1 }
               | {- empty -}                  { [] }

declaration    : statement                               { DEC_STMT $1 }
               | variable_declaration_assignment ';'     { DEC_VAR $1 }
               | function_declaration                    { DEC_FUNC $1 }
               | class_declaration                       { DEC_CLASS $1 }

statement      : expression_statement              { $1 }
               | print_statement                   { $1 }
               | block_statement                   { $1 }
               | conditional_statement             { $1 }
               | while_statement                   { $1 }
               | for_statement                     { $1 }
               | return_statement                  { $1 }
               | break_statement                   { $1 }
               | continue_statement                { $1 }

expression_statement  : expression ';'                    { EXPR_STMT $1 }
print_statement       : 'print' expression ';'            { PRINT_STMT $2 }
block_statement       : '{' declarations '}'              { BLOCK_STMT (reverse $2) }
conditional_statement : 'if' '(' expression ')' statement                         { IF_STMT $3 $5}
                      | 'if' '(' expression ')' statement 'else' statement        { IF_ELSE_STMT $3 $5 $7 }
while_statement       : 'while' '(' expression ')' statement                      { WHILE_STMT $3 $5 }
for_statement         : 'for' '(' ';'  ';' ')' statement                                  { FOR_STMT EMPTY_DEC EMPTY_EXP EMPTY_DEC $6 }
                      | 'for' '(' variable_declaration ';' ';' ')' statement              { FOR_STMT (DEC_VAR $3) EMPTY_EXP EMPTY_DEC $7 }
                      | 'for' '(' ';' expression ';' ')' statement                        { FOR_STMT EMPTY_DEC $4 EMPTY_DEC $7 }
                      | 'for' '(' ';' ';' variable_assignment ')' statement                        { FOR_STMT EMPTY_DEC EMPTY_EXP (DEC_VAR $5) $7 }
                      | 'for' '(' variable_declaration ';' expression ';' ')' statement               { FOR_STMT (DEC_VAR $3) $5 EMPTY_DEC $8 }
                      | 'for' '(' variable_declaration ';' ';' variable_assignment ')' statement               { FOR_STMT (DEC_VAR $3) EMPTY_EXP (DEC_VAR $6) $8 }
                      | 'for' '(' ';' expression ';' variable_assignment ')' statement             { FOR_STMT EMPTY_DEC $4 (DEC_VAR $6) $8 }
                      | 'for' '(' variable_declaration ';' expression ';' variable_assignment ')' statement    { FOR_STMT (DEC_VAR $3) $5 (DEC_VAR $7) $9 }
return_statement      : 'return' expression ';'                                                       { AST.RETURN $2 }
break_statement       : 'break' ';'                              { AST.BREAK }
continue_statement    : 'continue' ';'                            { AST.CONTINUE }

variable_declaration_assignment       : variable_declaration                 { $1 }
                                      | variable_assignment                  { $1 }
                                      | class_variable_assignment            { $1 }


variable_declaration                  : 'var' IDENTIFIER '=' expression   { VAR_DEC_DEF $2 $4 }
                                      | 'var' IDENTIFIER                  { VAR_DEC $2 }
variable_assignment                   : IDENTIFIER '=' expression         { VAR_DEF $1 $3 }
class_variable_assignment             : IDENTIFIER '.' IDENTIFIER '=' expression            { CLASS_VAR_DEF $1 $3 $5 }
                                      | 'this' '.' IDENTIFIER '=' expression                { THIS_VAR_DEF $3 $5 }

class_declaration          : 'class' IDENTIFIER '{' methods '}'   { CLASS_DEC $2 (map (DEC_FUNC) (reverse $4)) }
                           | 'class' IDENTIFIER '<' IDENTIFIER '{' methods '}' { SUB_CLASS_DEC $2 $4 (map (DEC_FUNC) (reverse $6)) }
methods                    : {- empty -}                          { [] }
                           | methods method_declaration           { $2 : $1 }

function_declaration       : 'fun' IDENTIFIER '(' parameters ')' block_statement     { FUNC_DEC $2 (reverse $4) $6 }
                           | 'fun' IDENTIFIER '(' ')' block_statement                { FUNC_DEC $2 [] $5 }
method_declaration         : IDENTIFIER '(' parameters ')' block_statement           { METHOD_DEC $1 (reverse $3) $5 }
                           | IDENTIFIER '(' ')' block_statement                      { METHOD_DEC $1 [] $4 }

parameters                 : parameters ',' IDENTIFIER            { (DEC_VAR (PARAM $3)) : $1 }
                           | IDENTIFIER                           { [(DEC_VAR (PARAM $1))] }

function_call  : IDENTIFIER '(' arguments ')'         { CALL $1 (reverse $3) }
               | IDENTIFIER '(' ')'                   { CALL $1 [] }
               | function_call '(' arguments ')'      { CALL_MULTI $1 (reverse $3) }
               | function_call '(' ')'                { CALL_MULTI $1 [] }

chain          : chaining                               { CHAIN (reverse $1)}
chaining       : 'this' '.' chaining                    { mconcat [$3, [LINK_THIS]] }
               | 'this' '.' IDENTIFIER                  { [(LINK_IDENTIFIER $3), (LINK_THIS)] }
               | 'this' '.' function_call               { [(LINK_CALL $3), (LINK_THIS)] }
               | 'super' '.' chaining                   { mconcat [$3, [LINK_SUPER]] }
               | 'super' '.' function_call              { [(LINK_CALL $3), LINK_SUPER] }
               | 'super' '.' IDENTIFIER                 { [(LINK_IDENTIFIER $3), (LINK_SUPER)] }
               | chaining '.' chaining                  { mconcat  [$3, $1] }
               | chaining '.' function_call             { (LINK_CALL $3):$1 }
               | chaining '.' IDENTIFIER                { (LINK_IDENTIFIER $3):$1 }
               | function_call '.' chaining             { mconcat [$3, [(LINK_CALL $1)]] }
               | IDENTIFIER '.' chaining                { mconcat [$3, [(LINK_IDENTIFIER $1)]] }
               | IDENTIFIER '.' IDENTIFIER              { [(LINK_IDENTIFIER $3), (LINK_IDENTIFIER $1)] }
               | IDENTIFIER '.' function_call           { [(LINK_CALL $3), (LINK_IDENTIFIER $1)] }
               | function_call '.' IDENTIFIER           { [(LINK_IDENTIFIER $3), (LINK_CALL $1)] }
               | function_call '.' function_call        { [(LINK_CALL $3), (LINK_CALL $1)] }

arguments      : arguments ',' expression             { $3 : $1 }
               | expression                           { [$1] }

expression     : literal        {EXP_LITERAL $1}
               | unary          {EXP_UNARY $1}
               | binary         {EXP_BINARY $1}
               | ternary        {EXP_TERNARY $1}
               | grouping       {EXP_GROUPING $1}
               | function_call  {EXP_CALL $1}
               | chain          {EXP_CHAIN $1}
               | 'this'         {EXP_THIS}

literal        : NUMBER         {AST.NUMBER $1}
               | STRING         {AST.STRING $1}
               | 'true'         {AST.TRUE}
               | 'false'        {AST.FALSE}
               | 'nil'          {AST.NIL}
               | IDENTIFIER     {IDENTIFIER_REFERENCE $1}

grouping       : '(' expression ')'              {GROUP $2}
unary          : '-' expression %prec UN         {UNARY_MINUS $2}
               | '!' expression %prec UN         {UNARY_NEGATE $2}
binary         : expression '==' expression      {BIN_EQ $1 $3}
               | expression '!=' expression      {BIN_NOT_EQ $1 $3}
               | expression '+' expression       {BIN_ADD $1 $3}
               | expression '-' expression       {BIN_SUB $1 $3}
               | expression '*' expression       {BIN_MUL $1 $3}
               | expression '/' expression       {BIN_DIV $1 $3}
               | expression '>' expression       {BIN_COMP_GREATER $1 $3}
               | expression '<' expression       {BIN_COMP_LESS $1 $3}
               | expression '>=' expression      {BIN_COMP_GREATER_EQ $1 $3}
               | expression '<=' expression      {BIN_COMP_LESS_EQ $1 $3}
               | expression 'and' expression     {BIN_AND $1 $3}
               | expression 'or' expression      {BIN_OR $1 $3}
ternary        : expression '?' expression ':' expression { TERNARY $1 $3 $5 }

{
parseError :: [Token] -> a
parseError tokens = error ("Parse error" ++ show tokens)


happyParser = parser . lexer

}
