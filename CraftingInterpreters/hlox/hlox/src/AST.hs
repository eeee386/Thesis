
module AST where
  
import qualified Data.Text as T

type TextType = T.Text
  
data EXPRESSION = EXP_LITERAL LITERAL | EXP_UNARY UNARY | EXP_BINARY BINARY | EXP_GROUPING GROUPING | NON_EXP TextType
instance Show EXPRESSION where 
  show (EXP_LITERAL x) = show x
  show (EXP_UNARY x) = show x
  show (EXP_BINARY x) = show x
  show (EXP_GROUPING x) = show x
  show (NON_EXP x) = show x

data LITERAL = NUMBER Double | STRING TextType | TRUE | FALSE | NIL
instance Show LITERAL where 
  show (NUMBER x) = show x
  show (STRING x) = T.unpack x
  show TRUE = "true"
  show FALSE = "false"
  show NIL = "nil"  
   

newtype GROUPING = GROUP EXPRESSION
instance Show GROUPING where 
  show (GROUP x) = mconcat ["(", show x, ")"]

data UNARY = UNARY_MINUS EXPRESSION | UNARY_BANG EXPRESSION
instance Show UNARY where 
  show (UNARY_MINUS x) = mconcat ["-", show x]
  show (UNARY_BANG x) = mconcat ["!", show x]

data BINARY = BIN EXPRESSION OPERATOR EXPRESSION
instance Show BINARY where 
  show (BIN x y z) = mconcat [show x, show y, show z]

data OPERATOR = EQUAL_EQUAL | BANG_EQUAL | LESS | LESS_EQUAL | GREATER | GREATER_EQUAL
               | PLUS  | MINUS | STAR | SLASH | NO_OP deriving Eq
               
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
  show NO_OP = "noop"
  