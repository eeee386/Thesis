module EvalTypes where

import AST
import NativeFunctionTypes
import Utils
import qualified Data.HashTable.IO as HT

-- Types
type Arity = Int
type Name = TextType
type ParentName = TextType
type ErrorMessage = TextType
type Scope = HT.BasicHashTable TextType EVAL
type Closure = [Scope]

-- IMPROVE: Maybe create a different class eval which after creating an instance
data EVAL = EVAL_NUMBER Double
          | EVAL_STRING TextType
          | EVAL_BOOL Bool
          | EVAL_NIL
          | RUNTIME_ERROR ErrorMessage
          | SKIP_EVAL
          | DEC_EVAL Name EVAL ID
          | FUNC_DEC_EVAL Name Arity [DECLARATION] STATEMENT Closure ID
          | NATIVE_FUNC_DEC_EVAL Name Arity [DECLARATION] NATIVE_FUNCTION_TYPES
          | CLASS_DEC_EVAL Name [DECLARATION] Closure ID
          | SUB_CLASS_DEC_EVAL Name ParentName [DECLARATION] Closure ID PARENT_ID
          | THIS_EVAL [Closure]
          | RETURN_EVAL EVAL
          | BREAK_EVAL
          | CONTINUE_EVAL


instance Show EVAL where
  show (EVAL_NUMBER x) = show x
  show (EVAL_STRING x) = show x
  show (EVAL_BOOL x) = show x
  show EVAL_NIL = "nil"
  show (RUNTIME_ERROR x) = mconcat ["RuntimeError: ", show x]
  show (DEC_EVAL x y _) = mconcat [show x, " = ",show y]
  show SKIP_EVAL = "skip"
  show (FUNC_DEC_EVAL iden arity params stmt _ _) = mconcat ["Function ", show iden, ", arity: ", show arity, ", params: ", show params, ", statement: ", show stmt]
  show (NATIVE_FUNC_DEC_EVAL iden arity params _) = mconcat ["<<native>> Function ", show iden, ", arity: ", show arity, ", params: ", show params]
  show (CLASS_DEC_EVAL name decs clos id) = mconcat ["Class: ", show name, "decs: ", show decs, "id: ", show id]
  show (SUB_CLASS_DEC_EVAL name pName decs _ id _) = mconcat ["Class: ", show name, "parent: ", show pName, "decs: ", show decs, "id: ", show id]
  show (RETURN_EVAL x) = "return: " ++ show x
  show (THIS_EVAL _) = "this"
  show BREAK_EVAL = "break"
  show CONTINUE_EVAL = "continue"

isRuntimeError :: EVAL -> Bool
isRuntimeError (RUNTIME_ERROR _) = True
isRuntimeError _ = False

isReturn :: EVAL -> Bool
isReturn (RETURN_EVAL x) = True
isReturn _ = False

isBreak :: EVAL -> Bool
isBreak BREAK_EVAL = True
isBreak _ = False

isContinue :: EVAL -> Bool
isContinue CONTINUE_EVAL = True
isContinue _ = False

isBreakOrContinue :: EVAL -> Bool
isBreakOrContinue eval = isBreak eval || isContinue eval

getValueFromReturn :: EVAL -> EVAL
getValueFromReturn (RETURN_EVAL x) = x
getValueFromReturn _ = EVAL_NIL

isSubClass :: EVAL -> Bool
isSubClass SUB_CLASS_DEC_EVAL {} = True
isSubClass _ = False


