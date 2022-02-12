module AST where

import qualified Data.Text as T
import Lexer (Token)
import qualified Data.Sequence as S
import Data.Maybe
import NativeFunctionTypes
import Utils

newtype PROGRAM = PROG [DECLARATION]
instance Show PROGRAM where
  show (PROG x) = show x

data DECLARATION = DEC_STMT STATEMENT | DEC_VAR VARIABLE_DECLARATION | DEC_FUNC FUNCTION_DECLARATION | DEC_CLASS CLASS_DECLARATION | PARSE_ERROR TextType (S.Seq Token) | SKIP_DEC deriving Eq

instance Show DECLARATION where
  show (DEC_STMT x) = show x
  show (DEC_VAR x) = show x
  --show (PARSE_ERROR errMsg tokens) = mconcat ["ParseError: ", show errMsg, ". In line: " ,show (line (S.index tokens (S.length tokens-1)))]
  show SKIP_DEC = "skip dec"
  show (DEC_FUNC x) = "function: " ++ show x
  show (DEC_CLASS x) = "class: " ++ show x

type IDENTIFIER = TextType
type PARAMETER = TextType

data VARIABLE_DECLARATION = VAR_DEC_DEF IDENTIFIER EXPRESSION | VAR_DEC IDENTIFIER | VAR_DEF IDENTIFIER EXPRESSION  deriving Eq
instance Show VARIABLE_DECLARATION where
  show (VAR_DEC_DEF iden expr) = mconcat ["var", " ", show iden, " = ", show expr]
  show (VAR_DEC iden) = mconcat ["var", " ", show iden]
  show (VAR_DEF iden expr) = mconcat [show iden, " = ", show expr]

data FUNCTION_DECLARATION = FUNC_DEC IDENTIFIER [PARAMETER] STATEMENT
                          | METHOD_DEC IDENTIFIER [PARAMETER] STATEMENT
                          deriving Eq

instance Show FUNCTION_DECLARATION where
  show (FUNC_DEC i p s) = mconcat ["function name: ", show i,"params: " , show p, "statements: ", show s]
  show (METHOD_DEC i p s) = mconcat ["method name: ", show i,"params: " , show p, "statements: ", show s]


data CLASS_DECLARATION = CLASS_DEC IDENTIFIER [FUNCTION_DECLARATION] deriving Eq
instance Show CLASS_DECLARATION where 
  show (CLASS_DEC i methods) = mconcat ["class name: ", show i, "  methods: ", show methods]

data FOR_LOOP = FOR_EMPTY STATEMENT
              | FOR_DEC VARIABLE_DECLARATION STATEMENT
              | FOR_MID EXPRESSION STATEMENT
              | FOR_END EXPRESSION STATEMENT
              | FOR_DEC_MID VARIABLE_DECLARATION EXPRESSION STATEMENT
              | FOR_DEC_END VARIABLE_DECLARATION EXPRESSION STATEMENT
              | FOR_MID_END EXPRESSION EXPRESSION STATEMENT
              | FOR_ALL VARIABLE_DECLARATION EXPRESSION EXPRESSION STATEMENT
              deriving Eq

instance Show FOR_LOOP where
  show (FOR_EMPTY x) = mconcat ["for(;;)", show x]
  show (FOR_DEC x y) = mconcat ["for(", show x, ";;)", show y]
  show (FOR_MID x y) = mconcat ["for(;", show x, ";)", show y]
  show (FOR_END x y) = mconcat ["for(;;", show x, ")", show y]
  show (FOR_DEC_MID x y z) = mconcat ["for(", show x, ";", show y, ";)", show z]
  show (FOR_DEC_END x y z) = mconcat ["for(;", show x, ";", show y, ")", show z]
  show (FOR_MID_END x y z) = mconcat ["for(;", show x, ";", show y, ")", show z]
  show (FOR_ALL w x y z) = mconcat ["for(", show w , ";", show x, ";", show y, ")", show z]



data STATEMENT = EXPR_STMT EXPRESSION 
               | PRINT_STMT EXPRESSION 
               | BLOCK_STMT [DECLARATION]
               | IF_STMT EXPRESSION STATEMENT 
               | IF_ELSE_STMT EXPRESSION STATEMENT STATEMENT
               | WHILE_STMT EXPRESSION STATEMENT
               | FOR_STMT FOR_LOOP
               | LOOP EXPRESSION DECLARATION STATEMENT
               | RETURN EXPRESSION deriving Eq

instance Show STATEMENT where 
  show (EXPR_STMT x) = show x
  show (PRINT_STMT x) = mconcat ["print ", show x]
  show (BLOCK_STMT x) = show x
  show (IF_STMT expr stmt) = mconcat ["if (", show expr, ")", show stmt]
  show (IF_ELSE_STMT expr ifStmt elseStmt) = mconcat ["if (", show expr, ") ", show ifStmt, " else ", show elseStmt]
  show (WHILE_STMT expr stmt) = mconcat ["while (", show expr, ")", show stmt]
  show (FOR_STMT x) = show x
  show (LOOP expr1 expr2 stmt) = mconcat ["loop ", show expr1, " ", show expr2, " ", show stmt]
  show (RETURN x) = "return " ++ show x

-- Tokens only needed in operator expression because there are some, that cannot be evaluated, and we want to show why
data EXPRESSION = EXP_LITERAL LITERAL 
                | EXP_UNARY UNARY
                | EXP_BINARY BINARY
                | EXP_TERNARY TERNARY
                | EXP_GROUPING GROUPING
                | EXP_CALL CALL
                deriving Eq

instance Show EXPRESSION where 
  show (EXP_LITERAL x) = show x
  show (EXP_UNARY x) = show x
  show (EXP_BINARY x) = show x
  show (EXP_GROUPING x) = show x
  show (EXP_TERNARY x) = show x
  show (EXP_CALL x) = mconcat ["Function: ", show x]

data LITERAL = NUMBER Double | STRING TextType | TRUE | FALSE | NIL | IDENTIFIER TextType ID deriving Eq
instance Show LITERAL where 
  show (NUMBER x) = show x
  show (STRING x) = T.unpack (T.concat [T.pack "\"", x, T.pack "\""])
  show TRUE = "true"
  show FALSE = "false"
  show NIL = "nil"
  show (IDENTIFIER x id) = show x ++ show id


newtype GROUPING = GROUP EXPRESSION deriving Eq
instance Show GROUPING where 
  show (GROUP x) = mconcat ["(", show x, ")"]

type ARGUMENT = EXPRESSION

data CALL = CALL IDENTIFIER [ARGUMENT] | CALL_MULTI CALL [ARGUMENT] deriving Eq
instance Show CALL where
  show (CALL lit args) = mconcat [show lit, "(", show args, ")"]
  show (CALL_MULTI call args) = mconcat [ show call, "(", show args, ")"]

data UNARY = UNARY_NEGATE EXPRESSION |
             UNARY_MINUS EXPRESSION
             deriving Eq
instance Show UNARY where 
  show (UNARY_NEGATE x) = mconcat ["!", show x]
  show (UNARY_MINUS x) = mconcat ["-", show x]


data BINARY = BIN_ADD EXPRESSION EXPRESSION |
              BIN_SUB EXPRESSION EXPRESSION |
              BIN_MUL EXPRESSION EXPRESSION |
              BIN_DIV EXPRESSION EXPRESSION |
              BIN_EQ EXPRESSION EXPRESSION  |
              BIN_NOT_EQ EXPRESSION EXPRESSION |
              BIN_COMP_LESS EXPRESSION EXPRESSION |
              BIN_COMP_LESS_EQ EXPRESSION EXPRESSION |
              BIN_COMP_GREATER EXPRESSION EXPRESSION |
              BIN_COMP_GREATER_EQ EXPRESSION EXPRESSION |
              BIN_AND EXPRESSION EXPRESSION |
              BIN_OR EXPRESSION EXPRESSION
              deriving Eq
instance Show BINARY where 
  show (BIN_ADD x z) = mconcat [show x, " + ", show z]
  show (BIN_SUB x z) = mconcat [show x, " - ", show z]
  show (BIN_MUL x z) = mconcat [show x, " * ", show z]
  show (BIN_DIV x z) = mconcat [show x, " / ", show z]
  show (BIN_EQ x z) = mconcat [show x, " == ", show z]
  show (BIN_COMP_LESS x z) = mconcat [show x, " < ", show z]
  show (BIN_COMP_LESS_EQ x z) = mconcat [show x, " <= ", show z]
  show (BIN_COMP_GREATER x z) = mconcat [show x, " > ", show z]
  show (BIN_COMP_GREATER_EQ x z) = mconcat [show x, " >= ", show z]
  show (BIN_AND x z) = mconcat [show x, " and ", show z]
  show (BIN_OR x z) = mconcat [show x, " or ", show z]

  
data TERNARY = TERNARY EXPRESSION EXPRESSION EXPRESSION deriving Eq
instance Show TERNARY where 
  show (TERNARY x y z) = mconcat [show x, show y, show z]
