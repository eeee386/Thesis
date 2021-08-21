-- TODO: Hold line param for Evaluation errors
module AST where
  
import qualified Data.Text as T
import TokenHelper (Token, line, TokenType)
import qualified Data.Sequence as S

type TextType = T.Text

data PROGRAM = PROG (S.Seq DECLARATION) | PROG_ERROR DECLARATION
instance Show PROGRAM where
  show (PROG x) = show x
  show (PROG_ERROR x) = show x

data DECLARATION = DEC_STMT STATEMENT | DEC_VAR VARIABLE_DECLARATION | PARSE_ERROR TextType (S.Seq Token)
instance Show DECLARATION where
  show (DEC_STMT x) = show x
  show (DEC_VAR x) = show x
  show (PARSE_ERROR errMsg tokens) = mconcat ["ParseError: ", show errMsg, ". In line: " ,show (line (S.index tokens (S.length tokens-1)))]

type IDENTIFIER = TokenType

data VARIABLE_DECLARATION = VAR_DEC_DEF IDENTIFIER EXPRESSION | VAR_DEC IDENTIFIER | VAR_DEF IDENTIFIER EXPRESSION (S.Seq Token)
instance Show VARIABLE_DECLARATION where
  show (VAR_DEC_DEF iden expr) = mconcat ["var", " ", show iden, " = ", show expr]
  show (VAR_DEC iden) = mconcat ["var", " ", show iden] 
  show (VAR_DEF iden expr _) = mconcat ["var", " ", show iden, " = ", show expr]

data STATEMENT = EXPR_STMT EXPRESSION | PRINT_STMT EXPRESSION | BLOCK_STMT (S.Seq DECLARATION)
instance Show STATEMENT where 
  show (EXPR_STMT x) = show x
  show (PRINT_STMT x) = show x
  show (BLOCK_STMT x) = show x

-- Tokens only needed in operator expression because there are some, that cannot be evaluated, and we want to show why
data EXPRESSION = EXP_LITERAL LITERAL 
                | EXP_UNARY UNARY (S.Seq Token) 
                | EXP_BINARY BINARY (S.Seq Token) 
                | EXP_TERNARY TERNARY (S.Seq Token) 
                | EXP_GROUPING GROUPING
                | NON_EXP String (S.Seq Token)

instance Show EXPRESSION where 
  show (EXP_LITERAL x) = show x
  show (EXP_UNARY x _) = show x
  show (EXP_BINARY x _) = show x
  show (EXP_GROUPING x) = show x
  show (NON_EXP x y) = mconcat [show x, " ", show y]
  show (EXP_TERNARY x _) = show x

data LITERAL = NUMBER Double | STRING TextType | TRUE | FALSE | NIL | IDENTIFIER TextType (S.Seq Token)
instance Show LITERAL where 
  show (NUMBER x) = show x
  show (STRING x) = T.unpack (T.concat [T.pack "\"", x, T.pack "\""])
  show TRUE = "true"
  show FALSE = "false"
  show NIL = "nil"  
  show (IDENTIFIER x y) = show x ++ show y
   

newtype GROUPING = GROUP EXPRESSION
instance Show GROUPING where 
  show (GROUP x) = mconcat ["(", show x, ")"]

data UNARY = UNARY OPERATOR EXPRESSION
instance Show UNARY where 
  show (UNARY op x) = mconcat [show op, show x]

data BINARY = BIN EXPRESSION OPERATOR EXPRESSION
instance Show BINARY where 
  show (BIN x y z) = mconcat [show x, show y, show z]
  
data TERNARY = TERN EXPRESSION OPERATOR EXPRESSION OPERATOR EXPRESSION
instance Show TERNARY where 
  show (TERN v w x y z) = mconcat [show v, show w, show x, show y, show z]

data OPERATOR = EQUAL_EQUAL | BANG_EQUAL | LESS | LESS_EQUAL | GREATER | GREATER_EQUAL
               | PLUS  | MINUS | STAR | SLASH | QUESTION_MARK | COLON | BANG deriving Eq
               
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
  
getParseError :: DECLARATION -> Maybe DECLARATION
getParseError (PARSE_ERROR x y) = Just (PARSE_ERROR x y)
getParseError _ = Nothing

getASTErrorFromStatement :: DECLARATION -> Maybe String
getASTErrorFromStatement (DEC_STMT (EXPR_STMT x)) = findASTError x
getASTErrorFromStatement (DEC_STMT (PRINT_STMT x)) = findASTError x
getASTErrorFromStatement (DEC_VAR (VAR_DEC_DEF _ x)) = findASTError x
getASTErrorFromStatement (DEC_VAR (VAR_DEF _ x _)) = findASTError x
getASTErrorFromStatement _ = Nothing


findASTError :: EXPRESSION -> Maybe String
findASTError (NON_EXP x y) = Just (show (NON_EXP x y))
findASTError (EXP_GROUPING (GROUP x)) = findASTError x
findASTError (EXP_UNARY (UNARY _ x) _) = findASTError x
findASTError (EXP_BINARY (BIN left _ right) _) = (++) <$> findASTError left <*> findASTError right
findASTError (EXP_TERNARY (TERN _ _ trueRes _ falseRes) _) = (++) <$> findASTError trueRes <*> findASTError falseRes
findASTError _ = Nothing
