module AST where

import qualified Data.Text as T
import Utils

newtype PROGRAM = PROG [DECLARATION]
instance Show PROGRAM where
  show (PROG x) = show x

-- DECLARATION

data DECLARATION = DEC_STMT STATEMENT | DEC_VAR VARIABLE_DECLARATION | R_DEC_VAR RESOLVED_VARIABLE_DECLARATION | DEC_FUNC FUNCTION_DECLARATION | DEC_CLASS CLASS_DECLARATION | R_DEC_CLASS RESOLVED_CLASS_DECLARATION | EMPTY_DEC deriving Eq

instance Show DECLARATION where
  show (DEC_STMT x) = show x
  show (DEC_VAR x) = show x
  show (R_DEC_VAR x) = show x
  show (DEC_FUNC x) = "function: " ++ show x
  show (DEC_CLASS x) = "class: " ++ show x
  show (R_DEC_CLASS x) = "class: " ++ show x
  show EMPTY_DEC = ""


type IDENTIFIER = TextType
type PARAMETER = TextType

data VARIABLE_DECLARATION = VAR_DEC_DEF IDENTIFIER EXPRESSION
                          | VAR_DEC IDENTIFIER
                          | VAR_DEF IDENTIFIER EXPRESSION
                          | PARAM IDENTIFIER
                          | CLASS_VAR_DEF IDENTIFIER IDENTIFIER EXPRESSION
                          | THIS_VAR_DEF IDENTIFIER EXPRESSION
                          deriving Eq
instance Show VARIABLE_DECLARATION where
  show (VAR_DEC_DEF iden expr) = mconcat ["var", " ", show iden, " = ", show expr]
  show (VAR_DEC iden) = mconcat ["var", " ", show iden]
  show (VAR_DEF iden expr) = mconcat [show iden, " = ", show expr]
  show (PARAM iden) = show iden

  
data FUNCTION_DECLARATION = FUNC_DEC IDENTIFIER [DECLARATION] STATEMENT
                          | R_FUNC_DEC IDENTIFIER [DECLARATION] STATEMENT ID
                          | RC_FUNC_DEC IDENTIFIER [DECLARATION] STATEMENT
                          | METHOD_DEC IDENTIFIER [DECLARATION] STATEMENT
                          deriving Eq

instance Show FUNCTION_DECLARATION where
  show (FUNC_DEC i p s) = mconcat ["function name: ", show i,"params: " , show p, "statements: ", show s]
  show (R_FUNC_DEC i p s _) = mconcat ["function name: ", show i,"params: " , show p, "statements: ", show s]
  show (RC_FUNC_DEC i p s) = mconcat ["function name: ", show i,"params: " , show p, "statements: ", show s]
  show (METHOD_DEC i p s) = mconcat ["method name: ", show i,"params: " , show p, "statements: ", show s]


type PARENT_ID = ID

data CLASS_DECLARATION = CLASS_DEC IDENTIFIER [DECLARATION] | SUB_CLASS_DEC IDENTIFIER IDENTIFIER [DECLARATION] deriving Eq
instance Show CLASS_DECLARATION where 
  show (CLASS_DEC i methods) = mconcat ["class name: ", show i, "  methods: ", show methods]
  show (SUB_CLASS_DEC iden parentIden methods) = mconcat ["class name: ", show iden, ", parent: ", show parentIden, ",  methods: ", show methods]

-- I keep the PARENT_ID on the RC_SUB_CLASS as it can be child of a class not in the closure
data RESOLVED_CLASS_DECLARATION = R_CLASS_DEC IDENTIFIER [DECLARATION] ID 
                                | R_SUB_CLASS_DEC IDENTIFIER IDENTIFIER [DECLARATION] ID PARENT_ID
                                | RC_CLASS_DEC IDENTIFIER [DECLARATION] 
                                | RC_SUB_CLASS_DEC IDENTIFIER IDENTIFIER [DECLARATION] PARENT_ID 
                                deriving Eq
instance Show RESOLVED_CLASS_DECLARATION where
  show (R_CLASS_DEC i methods _) = mconcat ["class name: ", show i, "  methods: ", show methods]
  show (R_SUB_CLASS_DEC iden parentIden methods _ _) = mconcat ["class name: ", show iden, ", parent: ", show parentIden, ",  methods: ", show methods]
  show (RC_CLASS_DEC i methods) = mconcat ["class name: ", show i, "  methods: ", show methods]
  show (RC_SUB_CLASS_DEC iden parentIden methods _) = mconcat ["class name: ", show iden, ", parent: ", show parentIden, ",  methods: ", show methods]

-- RC: in closure
data RESOLVED_VARIABLE_DECLARATION = R_VAR_DEC_DEF IDENTIFIER EXPRESSION ID 
                                   | R_VAR_DEC IDENTIFIER ID 
                                   | R_VAR_DEF IDENTIFIER EXPRESSION ID
                                   | R_CLASS_VAR_DEF IDENTIFIER IDENTIFIER EXPRESSION ID
                                   | R_THIS_VAR_DEF IDENTIFIER EXPRESSION
                                   | RC_VAR_DEC_DEF IDENTIFIER EXPRESSION
                                   | RC_VAR_DEC IDENTIFIER
                                   | RC_VAR_DEF IDENTIFIER EXPRESSION
                                   | RC_CLASS_VAR_DEF IDENTIFIER IDENTIFIER EXPRESSION

                                   deriving Eq
instance Show RESOLVED_VARIABLE_DECLARATION where
  show (R_VAR_DEC_DEF iden expr _) = mconcat ["var", " ", show iden, " = ", show expr]
  show (R_VAR_DEC iden _) = mconcat ["var", " ", show iden]
  show (R_VAR_DEF iden expr _) = mconcat [show iden, " = ", show expr]
  show (RC_VAR_DEC_DEF iden expr) = mconcat ["var", " ", show iden, " = ", show expr]
  show (RC_VAR_DEC iden) = mconcat ["var", " ", show iden]
  show (RC_VAR_DEF iden expr) = mconcat [show iden, " = ", show expr]






-- STATEMENT

data STATEMENT = EXPR_STMT EXPRESSION 
               | PRINT_STMT EXPRESSION 
               | BLOCK_STMT [DECLARATION]
               | IF_STMT EXPRESSION STATEMENT 
               | IF_ELSE_STMT EXPRESSION STATEMENT STATEMENT
               | WHILE_STMT EXPRESSION STATEMENT
               | FOR_STMT DECLARATION EXPRESSION DECLARATION STATEMENT
               | LOOP EXPRESSION STATEMENT
               | BREAK
               | CONTINUE
               | RETURN EXPRESSION deriving Eq

instance Show STATEMENT where 
  show (EXPR_STMT x) = show x
  show (PRINT_STMT x) = mconcat ["print ", show x]
  show (BLOCK_STMT x) = show x
  show (IF_STMT expr stmt) = mconcat ["if (", show expr, ")", show stmt]
  show (IF_ELSE_STMT expr ifStmt elseStmt) = mconcat ["if (", show expr, ") ", show ifStmt, " else ", show elseStmt]
  show (WHILE_STMT expr stmt) = mconcat ["while (", show expr, ")", show stmt]
  show (FOR_STMT x y z stmt) = mconcat ["for(", show x, ";", show y, ";", show z, ";", show stmt]
  show (LOOP expr stmt) = mconcat ["loop ", show expr, " ", show stmt]
  show BREAK = "break"
  show CONTINUE = "continue"
  show (RETURN x) = "return " ++ show x


-- EXPRESSION
data EXPRESSION = EXP_LITERAL LITERAL 
                | EXP_UNARY UNARY
                | EXP_BINARY BINARY
                | EXP_TERNARY TERNARY
                | EXP_GROUPING GROUPING
                | EXP_CALL CALL
                | EXP_CHAIN CHAIN
                | EXP_THIS
                | EMPTY_EXP
                deriving Eq

instance Show EXPRESSION where 
  show (EXP_LITERAL x) = show x
  show (EXP_UNARY x) = show x
  show (EXP_BINARY x) = show x
  show (EXP_GROUPING x) = show x
  show (EXP_TERNARY x) = show x
  show (EXP_CALL x) = mconcat ["Function: ", show x]
  show (EXP_CHAIN x) = show x
  show EXP_THIS = "this"
  show EMPTY_EXP = ""

data LITERAL = NUMBER Double | STRING TextType | TRUE | FALSE | NIL | IDENTIFIER_REFERENCE TextType | R_IDENTIFIER_REFERENCE TextType ID | R_REFERENCE_IN_CLOSURE TextType deriving Eq
instance Show LITERAL where 
  show (NUMBER x) = show x
  show (STRING x) = T.unpack (T.concat [T.pack "\"", x, T.pack "\""])
  show TRUE = "true"
  show FALSE = "false"
  show NIL = "nil"
  show (IDENTIFIER_REFERENCE x) = show x
  show (R_IDENTIFIER_REFERENCE x id) = show x ++ show id
  show (R_REFERENCE_IN_CLOSURE x) = show x



newtype GROUPING = GROUP EXPRESSION deriving Eq
instance Show GROUPING where 
  show (GROUP x) = mconcat ["(", show x, ")"]

type ARGUMENT = EXPRESSION

data CALL = CALL IDENTIFIER [ARGUMENT] | R_CALL IDENTIFIER [ARGUMENT] ID | RC_CALL IDENTIFIER [ARGUMENT] | CALL_MULTI CALL [ARGUMENT] deriving Eq
instance Show CALL where
  show (CALL lit args) = mconcat [show lit, "(", show args, ")"]
  show (R_CALL lit args _) = mconcat [show lit, "(", show args, ")"]
  show (RC_CALL lit args) = mconcat [show lit, "(", show args, ")"]
  show (CALL_MULTI call args) = mconcat [ show call, "(", show args, ")"]
  
-- CHAIN data structure: list but the first and last element CAN be IDENTIFIERs, and this and super can only be first 
data CHAIN_LINK = LINK_CALL CALL | LINK_IDENTIFIER IDENTIFIER | LINK_THIS | LINK_SUPER deriving Eq
instance Show CHAIN_LINK where
  show (LINK_CALL x) = show x
  show (LINK_IDENTIFIER x) = show x
  show LINK_THIS = "this"
  show LINK_SUPER = "super"

newtype CHAIN = CHAIN [CHAIN_LINK] deriving Eq
instance Show CHAIN where
  show (CHAIN links) = mconcat $ reverse $ foldl (\y x -> mconcat [show x, "."] : y) [] links
  

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


-- TODO: Maybe not the best solution
getIdentifierFromMethod :: DECLARATION -> TextType
getIdentifierFromMethod (DEC_FUNC (METHOD_DEC iden _ _)) = iden
getIdentifierFromMethod _ = T.pack ""

createDecFromStatement :: STATEMENT -> DECLARATION
createDecFromStatement = DEC_STMT

getIdentifierFromParams :: DECLARATION -> TextType
getIdentifierFromParams (DEC_VAR (PARAM iden)) = iden
getIdentifierFromParams _ = T.pack ""

isVariableDeclaration :: DECLARATION -> Bool
isVariableDeclaration (DEC_VAR _) = True
isVariableDeclaration (R_DEC_VAR _) = True
isVariableDeclaration _ = False

isCall :: CHAIN_LINK -> Bool
isCall (LINK_CALL _) = True
isCall _ = False

isLinkSuperOrThis :: CHAIN_LINK -> Bool
isLinkSuperOrThis x = isLinkThis x && isLinkSuper x

isLinkThis :: CHAIN_LINK -> Bool
isLinkThis LINK_THIS = True
isLinkThis _ = False

isLinkSuper ::  CHAIN_LINK -> Bool
isLinkSuper LINK_SUPER = True
isLinkSuper _ = False

isLinkCall :: CHAIN_LINK -> Bool
isLinkCall (LINK_CALL x) = True
isLinkCall _ = False
