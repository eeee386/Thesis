module AST where

import qualified Data.Text as T
import TokenHelper (Token, line, TokenType)
import qualified Data.Sequence as S
import Data.Maybe
import NativeFunctionTypes
import Utils

newtype PROGRAM = PROG (S.Seq DECLARATION)
instance Show PROGRAM where
  show (PROG x) = show x

data DECLARATION = DEC_STMT STATEMENT | DEC_VAR VARIABLE_DECLARATION | DEC_FUNC FUNCTION_DECLARATION | DEC_CLASS CLASS_DECLARATION | PARSE_ERROR TextType (S.Seq Token) | SKIP_DEC deriving Eq

instance Show DECLARATION where
  show (DEC_STMT x) = show x
  show (DEC_VAR x) = show x
  show (PARSE_ERROR errMsg tokens) = mconcat ["ParseError: ", show errMsg, ". In line: " ,show (line (S.index tokens (S.length tokens-1)))]
  show SKIP_DEC = "skip dec"
  show (DEC_FUNC x) = "function: " ++ show x
  show (DEC_CLASS x) = "class: " ++ show x

type IDENTIFIER = TokenType

data VARIABLE_DECLARATION = VAR_DEC_DEF IDENTIFIER EXPRESSION (S.Seq Token) ID | VAR_DEC IDENTIFIER (S.Seq Token) ID | VAR_DEF IDENTIFIER EXPRESSION (S.Seq Token) ID | PARAM_DEC IDENTIFIER (S.Seq Token) ID deriving Eq
instance Show VARIABLE_DECLARATION where
  show (VAR_DEC_DEF iden expr _ id) = mconcat ["var", " ", show iden, " = ", show expr, ";id: ", show id]
  show (VAR_DEC iden _ id) = mconcat ["var", " ", show iden, ";id: ", show id] 
  show (VAR_DEF iden expr _ id) = mconcat [show iden, " = ", show expr, ";id: ", show id]
  show (PARAM_DEC iden _ _) = mconcat ["param", " ", show iden, ";id: "]


data FUNCTION_STATEMENT = FUNC_STMT STATEMENT | NATIVE_FUNC_STMT NATIVE_FUNCTION_TYPES deriving Eq
instance Show FUNCTION_STATEMENT where
  show (FUNC_STMT x) = show x
  show (NATIVE_FUNC_STMT x) = show x

data FUNCTION_DECLARATION = FUNC_DEC IDENTIFIER PARAMETERS FUNCTION_STATEMENT ID deriving Eq
instance Show FUNCTION_DECLARATION where
  show (FUNC_DEC i p s _) = mconcat ["function name: ", show i,"params: " , show p, "statements: ", show s]

data CLASS_DECLARATION = CLASS_DEC IDENTIFIER (S.Seq DECLARATION) ID deriving Eq
instance Show CLASS_DECLARATION where 
  show (CLASS_DEC i methods id) = mconcat ["class name: ", show i, "  methods: ", show methods ++ ", id: ", show id] 

data STATEMENT = EXPR_STMT EXPRESSION 
               | PRINT_STMT EXPRESSION 
               | BLOCK_STMT (S.Seq DECLARATION)
               | IF_STMT EXPRESSION STATEMENT 
               | IF_ELSE_STMT EXPRESSION STATEMENT STATEMENT
               | WHILE_STMT EXPRESSION STATEMENT
               | FOR_STMT DECLARATION EXPRESSION DECLARATION STATEMENT
               | LOOP EXPRESSION DECLARATION STATEMENT
               | RETURN_NIL | RETURN EXPRESSION deriving Eq

instance Show STATEMENT where 
  show (EXPR_STMT x) = show x
  show (PRINT_STMT x) = mconcat ["print ", show x]
  show (BLOCK_STMT x) = show x
  show (IF_STMT expr stmt) = mconcat ["if (", show expr, ")", show stmt]
  show (IF_ELSE_STMT expr ifStmt elseStmt) = mconcat ["if (", show expr, ") ", show ifStmt, " else ", show elseStmt]
  show (WHILE_STMT expr stmt) = mconcat ["while (", show expr, ")", show stmt]
  show (FOR_STMT dec expr1 expr2 stmt) = mconcat ["for(", show dec, ";", show expr1, ";", show expr2, ")", show stmt]
  show (LOOP expr1 expr2 stmt) = mconcat ["loop ", show expr1, " ", show expr2, " ", show stmt]
  show RETURN_NIL = "return nil"
  show (RETURN x) = "return " ++ show x

-- Tokens only needed in operator expression because there are some, that cannot be evaluated, and we want to show why
data EXPRESSION = EXP_LITERAL LITERAL 
                | EXP_UNARY UNARY (S.Seq Token) 
                | EXP_BINARY BINARY (S.Seq Token) 
                | EXP_TERNARY TERNARY (S.Seq Token) 
                | EXP_GROUPING GROUPING
                | EXP_CALL CALL
                | NON_EXP String (S.Seq Token) deriving Eq

instance Show EXPRESSION where 
  show (EXP_LITERAL x) = show x
  show (EXP_UNARY x _) = show x
  show (EXP_BINARY x _) = show x
  show (EXP_GROUPING x) = show x
  show (NON_EXP x y) = mconcat [show x, " ", show y]
  show (EXP_TERNARY x _) = show x
  show (EXP_CALL x) = mconcat ["Function: ", show x]

data LITERAL = NUMBER Double | STRING TextType | TRUE | FALSE | NIL | IDENTIFIER TextType (S.Seq Token) ID deriving Eq
instance Show LITERAL where 
  show (NUMBER x) = show x
  show (STRING x) = T.unpack (T.concat [T.pack "\"", x, T.pack "\""])
  show TRUE = "true"
  show FALSE = "false"
  show NIL = "nil"
  show (IDENTIFIER x _ id) = show x ++ show id


newtype GROUPING = GROUP EXPRESSION deriving Eq
instance Show GROUPING where 
  show (GROUP x) = mconcat ["(", show x, ")"]
  
data CALL = CALL_FUNC EXPRESSION (S.Seq ARGUMENTS) ID deriving Eq
instance Show CALL where
  show (CALL_FUNC lit args _) = mconcat [show lit, "(", show args, ")"]

data UNARY = UNARY OPERATOR EXPRESSION deriving Eq
instance Show UNARY where 
  show (UNARY op x) = mconcat [show op, show x]

data BINARY = BIN EXPRESSION OPERATOR EXPRESSION deriving Eq
instance Show BINARY where 
  show (BIN x y z) = mconcat [show x, show y, show z]
  
data TERNARY = TERN EXPRESSION OPERATOR EXPRESSION OPERATOR EXPRESSION deriving Eq
instance Show TERNARY where 
  show (TERN v w x y z) = mconcat [show v, show w, show x, show y, show z]
  
  
data PARAMETERS = PARAMETERS (S.Seq DECLARATION) (S.Seq Token) | INVALID_PARAMS TextType (S.Seq Token) deriving Eq
instance Show PARAMETERS where
  show (PARAMETERS params _) = show params
  show (INVALID_PARAMS a t) = mconcat ["Invalid parameters: ", show a, show t]
  
data ARGUMENTS = ARGS (S.Seq EXPRESSION) | INVALID_ARGS TextType (S.Seq Token) deriving Eq
instance Show ARGUMENTS where
  show (ARGS exprs) = show exprs
  show (INVALID_ARGS t tokens) = mconcat [show t, " ", show tokens]

data OPERATOR = EQUAL_EQUAL | BANG_EQUAL | LESS | LESS_EQUAL | GREATER | GREATER_EQUAL
               | PLUS  | MINUS | STAR | SLASH | QUESTION_MARK | COLON | BANG | AND | OR deriving Eq

instance Show OPERATOR where 
  show EQUAL_EQUAL = "=="
  show BANG_EQUAL = "!="
  show LESS = "<"
  show LESS_EQUAL = "<="
  show GREATER = ">"
  show GREATER_EQUAL = ">="
  show PLUS = "+"
  show MINUS = "-"
  show STAR = "*"
  show SLASH = "/"
  show QUESTION_MARK = "?"
  show COLON = ":"
  show BANG = "!"
  show OR = " or "
  show AND = " and "
  
findParseError :: S.Seq DECLARATION -> S.Seq DECLARATION -> S.Seq DECLARATION
findParseError decs pdecs
  | S.null decs = pdecs
  | isParseError el = findParseError (S.drop 1 decs) (pdecs S.|> el)
  | isBlock el = findParseError (S.drop 1 decs) (pdecs S.>< findParseError (getDecsFromBlock el) S.empty)
  | otherwise = findParseError (S.drop 1 decs) pdecs
  where el = S.index decs 0
  
isBlock :: DECLARATION -> Bool
isBlock (DEC_STMT (BLOCK_STMT _)) = True
isBlock _ = False

getDecsFromBlock :: DECLARATION -> S.Seq DECLARATION
getDecsFromBlock (DEC_STMT (BLOCK_STMT x)) = x

isParseError :: DECLARATION -> Bool
isParseError (PARSE_ERROR _ _) = True
isParseError _ = False

isSkipDec :: DECLARATION -> Bool
isSkipDec (SKIP_DEC) = True
isSkipDec _ = False

isExpLiteralIdentifier :: EXPRESSION -> Bool
isExpLiteralIdentifier (EXP_LITERAL (IDENTIFIER _ _ _)) = True
isExpLiteralIdentifier _ = False


getASTErrorFromStatement :: DECLARATION -> Maybe String
getASTErrorFromStatement (DEC_STMT (EXPR_STMT x)) = findASTError x
getASTErrorFromStatement (DEC_STMT (PRINT_STMT x)) = findASTError x
getASTErrorFromStatement (DEC_VAR (VAR_DEC_DEF _ x _ _)) = findASTError x
getASTErrorFromStatement (DEC_VAR (VAR_DEF _ x _ _)) = findASTError x
getASTErrorFromStatement (DEC_STMT (BLOCK_STMT x)) = S.lookup 0 $ fmap fromJust $ S.filter isJust $ fmap getASTErrorFromStatement x
getASTErrorFromStatement (DEC_FUNC (FUNC_DEC _ _ (FUNC_STMT x) _)) = getASTErrorFromStatement (DEC_STMT x)
getASTErrorFromStatement _ = Nothing


findASTError :: EXPRESSION -> Maybe String
findASTError (NON_EXP x y) = Just (show (NON_EXP x y))
findASTError (EXP_GROUPING (GROUP x)) = findASTError x
findASTError (EXP_UNARY (UNARY _ x) _) = findASTError x
findASTError (EXP_BINARY (BIN left _ right) _) = (++) <$> findASTError left <*> findASTError right
findASTError (EXP_TERNARY (TERN _ _ trueRes _ falseRes) _) = (++) <$> findASTError trueRes <*> findASTError falseRes
findASTError _ = Nothing

createDecFromStatement :: STATEMENT -> DECLARATION
createDecFromStatement (EXPR_STMT x) = DEC_STMT (EXPR_STMT x)
createDecFromStatement (PRINT_STMT x) = DEC_STMT (PRINT_STMT x)
createDecFromStatement (BLOCK_STMT xs) = DEC_STMT (BLOCK_STMT xs)
createDecFromStatement (IF_STMT ex st) = DEC_STMT (IF_STMT ex st)
createDecFromStatement (IF_ELSE_STMT ex st1 st2) = DEC_STMT (IF_ELSE_STMT ex st1 st2)
createDecFromStatement (WHILE_STMT ex st) = DEC_STMT (WHILE_STMT ex st)
createDecFromStatement (FOR_STMT vDec ex iDec st) = DEC_STMT (FOR_STMT vDec ex iDec st)
createDecFromStatement (LOOP ex dec st) = DEC_STMT (LOOP ex dec st)
createDecFromStatement RETURN_NIL = DEC_STMT RETURN_NIL
createDecFromStatement (RETURN x) = DEC_STMT (RETURN x)


isNativeFunction :: FUNCTION_STATEMENT -> Bool
isNativeFunction (NATIVE_FUNC_STMT _) = True
isNativeFunction _ = False

getStatementFromFunctionStatement :: FUNCTION_STATEMENT -> STATEMENT
getStatementFromFunctionStatement (FUNC_STMT x) = x

getNativeFunctionFromFunctionStatement :: FUNCTION_STATEMENT -> NATIVE_FUNCTION_TYPES
getNativeFunctionFromFunctionStatement (NATIVE_FUNC_STMT x) = x
