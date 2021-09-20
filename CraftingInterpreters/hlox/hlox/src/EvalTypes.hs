module EvalTypes where

import AST
import qualified Data.Sequence as S
import qualified TokenHelper as TH
import qualified Data.Vector as V

-- Types
type Arity = Int
type Name = AST.TextType
type ErrorMessage = AST.TextType

data EVAL = EVAL_NUMBER Double
          | EVAL_STRING AST.TextType
          | EVAL_BOOL Bool
          | EVAL_NIL
          | RUNTIME_ERROR ErrorMessage (S.Seq TH.Token) 
          | SKIP_EVAL
          | DEC_EVAL Name EVAL ID
          | FUNC_DEC_EVAL Name Arity AST.PARAMETERS FUNCTION_STATEMENT
          | RETURN_EVAL EVAL
          deriving Eq


instance Show EVAL where
  show (EVAL_NUMBER x) = show x
  show (EVAL_STRING x) = show x
  show (EVAL_BOOL x) = show x
  show EVAL_NIL = "nil"
  show (RUNTIME_ERROR x neLines) = mconcat ["RuntimeError: ", show x, getLineError neLines]
  show (DEC_EVAL x y _) = mconcat [show x, " = ",show y]
  show SKIP_EVAL = "skip"
  show (FUNC_DEC_EVAL iden arity params stmt) = mconcat ["Function ", show iden, ", arity: ", show arity, ", params: ", show params, ", statement: ", show stmt]
  show (RETURN_EVAL x) = "return: " ++ show x

getLineError :: S.Seq TH.Token -> String
getLineError tokens = if firstLine /= secondLine then mconcat [". Between lines: ", show firstLine, "-", show secondLine] else mconcat [". In line: ", show firstLine]
  where firstLine = TH.line <$> S.lookup 0 tokens 
        secondLine = TH.line <$> S.lookup (S.length tokens - 1) tokens


isRuntimeError :: EVAL -> Bool
isRuntimeError (RUNTIME_ERROR _ _) = True
isRuntimeError _ = False

isReturn :: EVAL -> Bool
isReturn (RETURN_EVAL x) = True
isReturn _ = False

getValueFromReturn :: EVAL -> EVAL
getValueFromReturn (RETURN_EVAL x) = x
getValueFromReturn _ = EVAL_NIL


