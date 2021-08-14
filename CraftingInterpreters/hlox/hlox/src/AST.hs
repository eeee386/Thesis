-- TODO: Hold line param for Evaluation errors
module AST where
  
import qualified Data.Text as T
import TokenHelper (Token)
import qualified Data.Sequence as S

type TextType = T.Text

-- Lines only needed in operator expression because are the ones that can be items, that cannot be evaluated
data EXPRESSION = EXP_LITERAL LITERAL | EXP_UNARY UNARY (S.Seq Token) | EXP_BINARY BINARY (S.Seq Token) | EXP_TERNARY TERNARY (S.Seq Token) | EXP_GROUPING GROUPING | NON_EXP String (S.Seq Token)
instance Show EXPRESSION where 
  show (EXP_LITERAL x) = show x
  show (EXP_UNARY x _) = show x
  show (EXP_BINARY x _) = show x
  show (EXP_GROUPING x) = show x
  show (NON_EXP x y) = mconcat [show x, " ", show y]
  show (EXP_TERNARY x _) = show x

data LITERAL = NUMBER Double | STRING TextType | TRUE | FALSE | NIL
instance Show LITERAL where 
  show (NUMBER x) = show x
  show (STRING x) = T.unpack (T.concat [T.pack "\"", x, T.pack "\""])
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
  
data TERNARY = TERN EXPRESSION OPERATOR EXPRESSION OPERATOR EXPRESSION
instance Show TERNARY where 
  show (TERN v w x y z) = mconcat [show v, show w, show x, show y, show z]

data OPERATOR = EQUAL_EQUAL | BANG_EQUAL | LESS | LESS_EQUAL | GREATER | GREATER_EQUAL
               | PLUS  | MINUS | STAR | SLASH | QUESTION_MARK | COLON deriving Eq
               
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
  