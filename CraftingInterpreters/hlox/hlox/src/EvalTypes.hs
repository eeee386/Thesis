module EvalTypes where
  
import AST
import qualified Data.Sequence as S
import qualified TokenHelper as TH
  
data PROG_EVAL = EXPR_EVAL EVAL | PRINT_EVAL EVAL | BLOCK_EVAL (S.Seq PROG_EVAL) | DEC_EVAL AST.TextType EVAL deriving Show

data EVAL = EVAL_NUMBER Double | EVAL_STRING AST.TextType | EVAL_BOOL Bool | EVAL_NIL | NON_EVAL AST.TextType (S.Seq TH.Token) deriving Eq
instance Show EVAL where
  show (EVAL_NUMBER x) = show x
  show (EVAL_STRING x) = show x
  show (EVAL_BOOL x) = show x
  show EVAL_NIL = "nil"
  show (NON_EVAL x neLines) = mconcat ["RuntimeError: ", show x, getLineError neLines]
  
getLineError :: S.Seq TH.Token -> String
getLineError tokens = if firstLine /= secondLine then mconcat [". Between lines: ", show firstLine, "-", show secondLine] else mconcat [". In line: ", show firstLine]
  where firstLine = TH.line <$> S.lookup 0 tokens 
        secondLine = TH.line <$> S.lookup (S.length tokens - 1) tokens
        
hasRuntimeError :: PROG_EVAL -> Bool
hasRuntimeError (EXPR_EVAL (NON_EVAL _ _)) = True
hasRuntimeError (PRINT_EVAL (NON_EVAL _ _)) = True
hasRuntimeError (DEC_EVAL _ (NON_EVAL _ _)) = True
hasRuntimeError _ = False

createRuntimeError :: PROG_EVAL -> PROG_EVAL
createRuntimeError (EXPR_EVAL (NON_EVAL x y )) = PRINT_EVAL (NON_EVAL x y)
createRuntimeError (DEC_EVAL _ (NON_EVAL x y)) = PRINT_EVAL (NON_EVAL x y)
createRuntimeError x = x



