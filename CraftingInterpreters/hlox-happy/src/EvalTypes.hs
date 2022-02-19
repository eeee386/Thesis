module EvalTypes where

import AST
import qualified Data.Sequence as S
import NativeFunctionTypes
import Utils

-- Types
type Arity = Int
type Name = TextType
type ErrorMessage = TextType

data EVAL = EVAL_NUMBER Double
          | EVAL_STRING TextType
          | EVAL_BOOL Bool
          | EVAL_NIL
          | RUNTIME_ERROR ErrorMessage
          | SKIP_EVAL
          | DEC_EVAL Name EVAL ID
          | FUNC_DEC_EVAL Name Arity [PARAMETER] STATEMENT
          | NATIVE_FUNC_DEC_EVAL Name Arity [PARAMETER] NATIVE_FUNCTION_TYPES
          | RETURN_EVAL EVAL
          deriving Eq


instance Show EVAL where
  show (EVAL_NUMBER x) = show x
  show (EVAL_STRING x) = show x
  show (EVAL_BOOL x) = show x
  show EVAL_NIL = "nil"
  show (RUNTIME_ERROR x) = mconcat ["RuntimeError: ", show x]
  show (DEC_EVAL x y _) = mconcat [show x, " = ",show y]
  show SKIP_EVAL = "skip"
  show (FUNC_DEC_EVAL iden arity params stmt) = mconcat ["Function ", show iden, ", arity: ", show arity, ", params: ", show params, ", statement: ", show stmt]
  show (NATIVE_FUNC_DEC_EVAL iden arity params _) = mconcat ["<<native>> Function ", show iden, ", arity: ", show arity, ", params: ", show params]
  show (RETURN_EVAL x) = "return: " ++ show x

{-
getLineError :: S.Seq TH.Token -> String
getLineError tokens = if firstLine /= secondLine then mconcat [". Between lines: ", show firstLine, "-", show secondLine] else mconcat [". In line: ", show firstLine]
  where firstLine = TH.line <$> S.lookup 0 tokens 
        secondLine = TH.line <$> S.lookup (S.length tokens - 1) tokens
-}

isRuntimeError :: EVAL -> Bool
isRuntimeError (RUNTIME_ERROR _) = True
isRuntimeError _ = False

isReturn :: EVAL -> Bool
isReturn (RETURN_EVAL x) = True
isReturn _ = False

getValueFromReturn :: EVAL -> EVAL
getValueFromReturn (RETURN_EVAL x) = x
getValueFromReturn _ = EVAL_NIL


