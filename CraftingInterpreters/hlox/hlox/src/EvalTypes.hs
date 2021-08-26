module EvalTypes where
  
import AST
import qualified Data.Sequence as S
import qualified TokenHelper as TH

data EVAL = EVAL_NUMBER Double | EVAL_STRING AST.TextType | EVAL_BOOL Bool | EVAL_NIL | RUNTIME_ERROR AST.TextType (S.Seq TH.Token) | SKIP_EVAL | DEC_EVAL AST.TextType EVAL  deriving Eq
instance Show EVAL where
  show (EVAL_NUMBER x) = show x
  show (EVAL_STRING x) = show x
  show (EVAL_BOOL x) = show x
  show EVAL_NIL = "nil"
  show (RUNTIME_ERROR x neLines) = mconcat ["RuntimeError: ", show x, getLineError neLines]
  show (DEC_EVAL x y) = mconcat [show x, " = ",show y]
  show SKIP_EVAL = "skip"
  
getLineError :: S.Seq TH.Token -> String
getLineError tokens = if firstLine /= secondLine then mconcat [". Between lines: ", show firstLine, "-", show secondLine] else mconcat [". In line: ", show firstLine]
  where firstLine = TH.line <$> S.lookup 0 tokens 
        secondLine = TH.line <$> S.lookup (S.length tokens - 1) tokens
        
        
hasRuntimeError :: EVAL -> Bool
hasRuntimeError (RUNTIME_ERROR _ _) = True
hasRuntimeError _ = False