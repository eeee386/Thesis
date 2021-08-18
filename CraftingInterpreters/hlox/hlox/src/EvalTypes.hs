module EvalTypes where
  
import AST
import qualified Data.Sequence as S
import qualified TokenHelper as TH
  
data PROG_EVAL = EXPR_EVAL EVAL | PRINT_EVAL EVAL | DEC_EVAL AST.TextType EVAL

data EVAL = EVAL_NUMBER Double | EVAL_STRING AST.TextType | EVAL_BOOL Bool | EVAL_NIL | NON_EVAL AST.TextType (S.Seq TH.Token) deriving Eq
instance Show EVAL where
  show (EVAL_NUMBER x) = show x
  show (EVAL_STRING x) = show x
  show (EVAL_BOOL x) = show x
  show EVAL_NIL = "nil"
  show (NON_EVAL x neLines) = mconcat ["RuntimeError: ", show x, getLineError neLines]
  
getLineError :: S.Seq TH.Token -> String
getLineError tokens = if firstLine /= secondLine then mconcat [". Between lines: ", show firstLine, "-", show secondLine] else mconcat [". In line: ", show firstLine]
  where firstLine = TH.line (S.index tokens 0) 
        secondLine = TH.line (S.index tokens (S.length tokens - 1))

