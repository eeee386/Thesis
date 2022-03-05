{-# LANGUAGE OverloadedStrings #-}


module Eval where
import EvalTypes
import EvalMeta
import Utils
import Data.Text as T
import Data.Maybe
import AST
import Data.Vector as V
import Data.List as L
import Data.HashTable.IO as HT

evalProgram :: [DECLARATION] -> V.Vector EVAL -> IO META
evalProgram x vector = createGlobalMeta vector >>= evalDeclarations x

evalBlock :: [DECLARATION]  -> META -> IO META
evalBlock = evalDeclarations

evalDeclarations :: [DECLARATION] -> META -> IO META
evalDeclarations decs meta = do
  if L.null decs || EvalMeta.isReturn meta then do
    return meta
  else do
    let (current:rest) = decs
    newMeta <- evalDeclaration current meta
    let ev = eval newMeta
    case ev of
      (RETURN_EVAL x)  -> return newMeta{eval=x, EvalMeta.isReturn=True}
      CONTINUE_EVAL -> return newMeta{eval=ev}
      BREAK_EVAL -> return newMeta{eval=ev}
      (RUNTIME_ERROR x) -> do
        print ev
        return newMeta{eval=ev}
      _ -> evalDeclarations rest newMeta




evalDeclaration :: DECLARATION -> META -> IO META
evalDeclaration (DEC_STMT (PRINT_STMT x)) meta = do
  newMeta <- evalExpression x meta
  print (eval newMeta)
  return newMeta
evalDeclaration (DEC_STMT (EXPR_STMT x)) meta = evalExpression x meta

evalDeclaration (DEC_STMT BREAK) meta = return meta{eval=BREAK_EVAL}
evalDeclaration (DEC_STMT CONTINUE) meta = return meta{eval=CONTINUE_EVAL}

evalDeclaration (R_DEC_VAR (R_VAR_DEC_DEF iden expr id)) meta = evalExpression expr meta >>= handleVarDefinition iden id
evalDeclaration (R_DEC_VAR (R_VAR_DEC iden id)) meta = return meta{eval=DEC_EVAL iden EVAL_NIL id}
evalDeclaration (R_DEC_VAR (R_VAR_DEF iden expr id)) meta = evalExpression expr meta >>= handleVarDefinition iden id
evalDeclaration (R_DEC_VAR (R_CLASS_VAR_DEF iden pIden expr classId)) meta = do
    classEval <- findValueInMeta classId meta
    let evalClassDec newMeta = case classEval of
          (CLASS_DEC_EVAL name evals clos id) -> do
            newClos <- updateScopeInClosure pIden (eval newMeta) clos
            addUpdateValueToMeta id newMeta{eval=CLASS_DEC_EVAL name evals newClos id}
          (SUB_CLASS_DEC_EVAL name parentName evals clos id parentId) -> do
            newClos <- updateScopeInClosure pIden (eval newMeta) clos
            addUpdateValueToMeta id newMeta{eval=SUB_CLASS_DEC_EVAL name parentName evals newClos id parentId}
          _ -> return newMeta{eval=RUNTIME_ERROR "Unknown error"}
    evalExpression expr meta >>= checkIfLastEvalIsRuntimeError evalClassDec


evalDeclaration (R_DEC_VAR (RC_VAR_DEC_DEF iden expr)) meta = evalExpression expr meta >>= checkIfLastEvalIsRuntimeError (addUpdateClosureInMeta iden)
evalDeclaration (R_DEC_VAR (RC_VAR_DEC iden)) meta = addUpdateClosureInMeta iden meta{eval=EVAL_NIL}
evalDeclaration (R_DEC_VAR (RC_VAR_DEF iden expr)) meta = evalExpression expr meta >>= checkIfLastEvalIsRuntimeError (addUpdateClosureInMeta iden)

evalDeclaration (DEC_STMT (BLOCK_STMT x)) meta = evalBlock x meta
evalDeclaration (DEC_STMT (IF_STMT expr stmt)) meta = evalExpression expr meta >>= checkIfLastEvalIsRuntimeError evalIf
  where evalIf newMeta = if maybeEvalTruthy (eval newMeta) == Just True then do
                           evalDeclaration (createDecFromStatement stmt) newMeta
                         else return newMeta
evalDeclaration (DEC_STMT (IF_ELSE_STMT expr stmt1 stmt2)) meta = evalExpression expr meta >>= checkIfLastEvalIsRuntimeError evalIfElse
  where evalIfElse newMeta = if maybeEvalTruthy (eval newMeta) == Just True then evalDeclaration (createDecFromStatement stmt1) newMeta else evalDeclaration (createDecFromStatement stmt2) newMeta
evalDeclaration (DEC_STMT (LOOP expr stmt)) meta = evalExpression expr meta >>= checkIfLastEvalIsRuntimeError evalLoop
  where lastEval = eval meta
        evalLoop newMeta = if maybeEvalTruthy (eval newMeta) == Just True && not (isBreak lastEval) && not (isRuntimeError lastEval) then do
                             evalDeclaration (createDecFromStatement stmt) newMeta >>= evalDeclaration (DEC_STMT (LOOP expr stmt))
                           else do
                             return newMeta

-- closure meta will be an empty list, so it could be an [] as well
evalDeclaration (DEC_FUNC (R_FUNC_DEC iden params stmt id)) meta = functionDecEvalHelper (addUpdateValueToMeta id) iden params stmt id meta
evalDeclaration (DEC_FUNC (RC_FUNC_DEC iden params stmt)) meta = functionDecEvalHelper (addUpdateScopeInMeta iden) iden params stmt NON_ID meta
evalDeclaration (DEC_FUNC (METHOD_DEC iden params stmt)) meta = functionDecEvalHelper (addUpdateScopeInMeta iden) iden params stmt NON_ID meta
evalDeclaration (R_DEC_CLASS (R_CLASS_DEC iden decs id)) meta = addUpdateValueToMeta id meta{eval=CLASS_DEC_EVAL iden decs (closure meta) id}
evalDeclaration (R_DEC_CLASS (RC_CLASS_DEC iden decs)) meta = addUpdateScopeInMeta iden meta{eval=CLASS_DEC_EVAL iden decs (closure meta) NON_ID}
evalDeclaration (R_DEC_CLASS (R_SUB_CLASS_DEC iden parentIden decs id parentId)) meta = addUpdateValueToMeta id meta{eval=SUB_CLASS_DEC_EVAL iden parentIden decs (closure meta) id parentId}
evalDeclaration (R_DEC_CLASS (RC_SUB_CLASS_DEC iden parentIden decs parentId)) meta = addUpdateScopeInMeta iden meta{eval=SUB_CLASS_DEC_EVAL iden parentIden decs (closure meta) NON_ID parentId}
evalDeclaration (DEC_STMT (RETURN exp)) meta = do 
  expMeta <- evalExpression exp meta
  return expMeta{eval=RETURN_EVAL (eval expMeta)}

evalDeclaration dec meta = do
  return meta{eval=RUNTIME_ERROR "Unknown error"}


functionDecEvalHelper :: (META -> IO META) -> TextType -> [DECLARATION] -> STATEMENT -> ID -> META -> IO META
functionDecEvalHelper addUpdateFunc iden params stmt id meta = addUpdateFunc meta{eval=evalFunc}
  where evalFunc = FUNC_DEC_EVAL iden (L.length params) params stmt (closure meta) id

evalExpression :: EXPRESSION -> META -> IO META
evalExpression (EXP_LITERAL (NUMBER x)) meta = return meta{eval=EVAL_NUMBER x}
evalExpression (EXP_LITERAL (STRING x)) meta = return meta{eval=EVAL_STRING x}
evalExpression (EXP_LITERAL FALSE) meta = return meta{eval=EVAL_BOOL False}
evalExpression (EXP_LITERAL TRUE) meta = return meta{eval=EVAL_BOOL True}
evalExpression (EXP_LITERAL NIL) meta = return meta{eval=EVAL_NIL}
evalExpression (EXP_LITERAL (R_IDENTIFIER_REFERENCE _ id)) meta = do
  val <- findValueInMeta id meta
  return meta{eval=val}
evalExpression (EXP_LITERAL (R_REFERENCE_IN_CLOSURE iden)) meta = do
  val <- findValueInClosureInMeta iden meta
  return meta{eval=val}

evalExpression (EXP_GROUPING (GROUP x)) meta = evalExpression x meta

evalExpression (EXP_UNARY (UNARY_MINUS x)) meta = do
  newMeta <- evalExpression x meta
  let num = maybeEvalNumber (eval newMeta)
  if isJust num then return newMeta{eval=EVAL_NUMBER (-(fromJust num))} else return newMeta{eval=RUNTIME_ERROR "Unary minus can only be used on numbers"}
evalExpression (EXP_UNARY (UNARY_NEGATE x)) meta = do
  newMeta <- evalExpression x meta
  let bool = maybeEvalTruthy (eval newMeta)
  if isJust bool then return newMeta{eval=EVAL_BOOL (not (fromJust bool))} else return newMeta{eval=RUNTIME_ERROR "Can only negate truthy values (bool, string, number)"}

evalExpression (EXP_BINARY (BIN_ADD left right)) meta = do
  leftMeta <- evalExpression left meta
  let evaledLeft = eval leftMeta
  rightMeta <- evalExpression right leftMeta
  let evaledRight = eval rightMeta
  return (addHelper evaledLeft evaledRight rightMeta)
evalExpression (EXP_BINARY (BIN_SUB left right)) meta = binaryNumericHelper left right EVAL_NUMBER (-) meta
evalExpression (EXP_BINARY (BIN_MUL left right)) meta = binaryNumericHelper left right EVAL_NUMBER (*) meta
evalExpression (EXP_BINARY (BIN_DIV left right)) meta = binaryNumericHelper left right EVAL_NUMBER (/) meta
evalExpression (EXP_BINARY (BIN_COMP_LESS left right)) meta = binaryNumericHelper left right EVAL_BOOL (<) meta
evalExpression (EXP_BINARY (BIN_COMP_LESS_EQ left right)) meta = binaryNumericHelper left right EVAL_BOOL (<=) meta
evalExpression (EXP_BINARY (BIN_COMP_GREATER left right)) meta = binaryNumericHelper left right EVAL_BOOL (>) meta
evalExpression (EXP_BINARY (BIN_COMP_GREATER_EQ left right)) meta = binaryNumericHelper left right EVAL_BOOL (>=) meta
evalExpression (EXP_BINARY (BIN_EQ left right)) meta = binaryBoolHelper left right (createEquality id) meta
evalExpression (EXP_BINARY (BIN_NOT_EQ left right)) meta = binaryBoolHelper left right (createEquality not) meta
evalExpression (EXP_BINARY (BIN_AND left right)) meta = binaryBoolHelper left right createAnd meta
evalExpression (EXP_BINARY (BIN_OR left right)) meta = binaryBoolHelper left right createOr meta
evalExpression (EXP_TERNARY (TERNARY predi trueRes falseRes)) meta = evalExpression predi meta >>= evalTernary trueRes falseRes

evalExpression (EXP_CALL (CALL call_iden args)) meta = handleCallEval args (findValueInClosureInMeta call_iden) meta
evalExpression (EXP_CALL (R_CALL _ args id)) meta = handleCallEval args (findValueInMeta id) meta
evalExpression (EXP_CALL (RC_CALL call_iden args)) meta = handleCallEval args (findValueInClosureInMeta call_iden) meta
evalExpression (EXP_CALL (CALL_MULTI call args)) meta = evalExpression (EXP_CALL call) meta >>= handleCallEval args multiCallGetFunc

evalExpression (EXP_CHAIN (CHAIN (l:links))) meta = do
  case l of
    LINK_THIS -> do
      classEval <- findValueInClosureInMeta "this" meta
      evalExpression (EXP_CHAIN (CHAIN links)) meta{eval=classEval}
    LINK_SUPER -> do
      (SUB_CLASS_DEC_EVAL _ parentName _ _ _ parentId) <- findValueInClosureInMeta "this" meta
      parentClassEval <- findParentClass parentName parentId meta
      evalExpression (EXP_CHAIN (CHAIN links)) meta{eval=parentClassEval}
    LINK_CALL x -> do
      case eval meta of
        (CLASS_DEC_EVAL _ _ clos _) -> handleChainCall l links clos meta
        (SUB_CLASS_DEC_EVAL _ _ _ clos _ _) -> handleChainCall l links clos meta
        _ -> handleChainCall l links (closure meta) meta
    -- Link Identifier is the ending of the chain
    (LINK_IDENTIFIER x) -> do
      case eval meta of
        (CLASS_DEC_EVAL _ _ clos _) -> handleChainIdentifier l links clos meta
        (SUB_CLASS_DEC_EVAL _ _ _ clos _ _) -> handleChainIdentifier l links clos meta
        _ -> return meta{eval=RUNTIME_ERROR "Dot operation is only permitted on classes"}
    (R_LINK_IDENTIFIER _ id) -> do
      ev <- findValueInMeta id meta
      evalExpression (EXP_CHAIN (CHAIN links)) meta{eval=ev}
    (RC_LINK_IDENTIFIER iden) -> do 
      ev <- findValueInClosureInMeta iden meta
      evalExpression (EXP_CHAIN (CHAIN links)) meta{eval=ev}
evalExpression (EXP_CHAIN (CHAIN [])) meta = return meta

evalExpression EXP_THIS meta = do
  ev <- findValueInClosureInMeta "this" meta
  return meta{eval=ev}
evalExpression exp meta = do
  print "fails"
  print exp
  return meta{eval=RUNTIME_ERROR "Expression cannot be evaluated"}


-- Resolver already adds the init function to the  
handleCallEval :: [ARGUMENT] -> (META -> IO EVAL) -> META -> IO META
handleCallEval args findDec meta = do
  ev <- findDec meta
  case ev of 
    FUNC_DEC_EVAL {} -> handleFunctionCall args ev meta
    CLASS_DEC_EVAL name decs _ id -> handleClassInitCall args decs (\clos -> CLASS_DEC_EVAL name decs clos id) meta
    SUB_CLASS_DEC_EVAL name pName decs _ id pId -> do handleClassInitCall args decs (\clos -> SUB_CLASS_DEC_EVAL name pName decs clos id pId) meta


handleClassInitCall :: [ARGUMENT] -> [DECLARATION] -> (Closure -> EVAL) -> META -> IO META
handleClassInitCall args decs fact meta = do
  newMeta <- addNewScopeToMeta meta >>= handleMethodsEval decs
  init <- findValueInClosureInMeta "init" newMeta
  initMeta <- handleFunctionCall args init newMeta
  deleteScopeFromMeta initMeta{eval=fact (closure initMeta)}

handleChainCall :: CHAIN_LINK -> [CHAIN_LINK] -> Closure -> META -> IO META
handleChainCall (LINK_CALL (CALL iden args)) links clos meta = do
  ev <- findValueInClosure iden clos
  handleFunctionCall args ev meta >>= evalExpression (EXP_CHAIN (CHAIN links))

handleChainCall (LINK_CALL x) links clos meta = evalExpression (EXP_CALL x) meta >>= evalExpression (EXP_CHAIN (CHAIN links))


handleChainIdentifier :: CHAIN_LINK -> [CHAIN_LINK] -> Closure -> META -> IO META
handleChainIdentifier link links clos meta = do
  let (LINK_IDENTIFIER iden) = link
  eval <- maybeFindValueInClosure iden clos
  if isNothing eval then do
    return meta{eval=RUNTIME_ERROR "This is not a property on the class"}
  else do
    evalExpression (EXP_CHAIN (CHAIN links)) meta{eval=fromJust eval}


handleFunctionCall :: [ARGUMENT] -> EVAL -> META -> IO META
handleFunctionCall args ev meta = do
  let (FUNC_DEC_EVAL _ arity params stmt clos _) = ev
  if arity /= L.length args then return meta{eval=RUNTIME_ERROR "Arity is not the same"} else do
    let numberOfClos = L.length clos
    updatedClosMeta <- addSavedClosure clos meta >>= addNewScopeToMeta
    evaledArgsMetas <- Prelude.mapM (`evalExpression` updatedClosMeta) args
    if L.any (isRuntimeError . eval) evaledArgsMetas then return updatedClosMeta{eval=fromJust (L.find isRuntimeError (L.map eval evaledArgsMetas))} else do
      handleArgumentsEval params (L.map eval evaledArgsMetas) updatedClosMeta >>= evalDeclaration (createDecFromStatement stmt) >>= cleanUpFunction numberOfClos

multiCallGetFunc :: META -> IO EVAL
multiCallGetFunc meta = return (eval meta)  

handleArgumentsEval :: [DECLARATION] -> [EVAL] ->  META -> IO META
handleArgumentsEval (p:params) (e:evals) meta = do
  let (DEC_VAR (PARAM iden)) = p
  newMeta <- addUpdateScopeInMetaWithEval iden e meta
  handleArgumentsEval params evals newMeta
handleArgumentsEval [] [] meta = return meta

handleMethodsEval :: [DECLARATION] -> META -> IO META
handleMethodsEval (d:decs) meta = evalDeclaration d meta >>= handleMethodsEval decs
handleMethodsEval [] meta = return meta

cleanUpFunction :: Int -> META -> IO META
cleanUpFunction numberOfClos meta = setReturnToFalse meta >>= deleteScopeFromMeta >>= deleteSavedClosure numberOfClos

checkIfLastEvalIsRuntimeError :: (META -> IO META) -> META -> IO META
checkIfLastEvalIsRuntimeError func meta = do
  case eval meta of
    (RUNTIME_ERROR _) -> return meta
    _ -> func meta

-- Helpers for operations
maybeEvalNumber :: EVAL -> Maybe Double
maybeEvalNumber (EVAL_NUMBER x) = Just x
maybeEvalNumber _ = Nothing

maybeEvalTruthy :: EVAL -> Maybe Bool
maybeEvalTruthy (EVAL_BOOL False) = Just False
maybeEvalTruthy (EVAL_BOOL True) = Just True
maybeEvalTruthy (EVAL_NUMBER _) = Just True
maybeEvalTruthy (EVAL_STRING _) = Just True
maybeEvalTruthy _ = Nothing

maybeEvalString :: EVAL -> Maybe TextType
maybeEvalString (EVAL_STRING x) = Just x
maybeEvalString _ = Nothing

concatTwoString :: TextType -> TextType -> EVAL
concatTwoString l r = EVAL_STRING (T.concat [l,r])

createMathOp :: (a -> EVAL)-> Maybe Double -> Maybe Double -> (Double -> Double -> a)  -> EVAL
createMathOp x l r f = if isJust l && isJust r then x (f (fromJust l) (fromJust r)) else RUNTIME_ERROR "Operands must be numbers"

createOr :: EVAL -> EVAL -> EVAL
createOr l r = if maybeEvalTruthy l == Just True then l else r

createAnd :: EVAL -> EVAL -> EVAL
createAnd l r = if maybeEvalTruthy l == Just False then l else r

equalityHelper :: (Eq a) =>  (Bool -> Bool) -> a -> a -> EVAL
equalityHelper ch l r  = if l == r then EVAL_BOOL (ch True) else EVAL_BOOL (ch False)

createEquality :: (Bool -> Bool) -> EVAL -> EVAL -> EVAL
createEquality ch (EVAL_NUMBER l) (EVAL_NUMBER r) = equalityHelper ch l r
createEquality ch (EVAL_STRING l) (EVAL_STRING r) = equalityHelper ch l r
createEquality ch (EVAL_BOOL l) (EVAL_BOOL r) = equalityHelper ch l r
createEquality ch EVAL_NIL EVAL_NIL = EVAL_BOOL (ch True)
createEquality ch _ _ = EVAL_BOOL (ch False)

addHelper :: EVAL -> EVAL -> META -> META
addHelper left right meta
  | isJust maybeLeftNum && isJust maybeRightNum = meta{eval=EVAL_NUMBER (fromJust maybeLeftNum + fromJust maybeRightNum)}
  | isJust maybeLeftString && isJust maybeRightString = meta{eval=concatTwoString (fromJust maybeLeftString) (fromJust maybeRightString)}
  | otherwise = meta{eval=RUNTIME_ERROR "Type error: use only strings or only numbers as operands"}
  where maybeLeftNum = maybeEvalNumber left
        maybeRightNum = maybeEvalNumber right
        maybeLeftString = maybeEvalString left
        maybeRightString = maybeEvalString right

binaryNumericHelper :: EXPRESSION -> EXPRESSION -> (a -> EVAL) -> (Double -> Double -> a) -> META -> IO META
binaryNumericHelper left right fact op meta = do
  leftMeta <- evalExpression left meta
  let maybeLeftNum = maybeEvalNumber(eval leftMeta)
  rightMeta <- evalExpression right leftMeta
  let maybeRightNum = maybeEvalNumber (eval rightMeta)
  return rightMeta{eval=createMathOp fact maybeLeftNum maybeRightNum op}

binaryBoolHelper :: EXPRESSION -> EXPRESSION -> (EVAL -> EVAL -> EVAL) ->  META -> IO META
binaryBoolHelper left right handler meta = do
  leftMeta <- evalExpression left meta
  let leftEval = eval leftMeta
  rightMeta <- evalExpression right leftMeta
  let rightEval = eval rightMeta
  return rightMeta{eval=handler leftEval rightEval}


evalTernary :: EXPRESSION -> EXPRESSION -> META -> IO META
evalTernary trueRes falseRes meta
  | preppedPred == Just True = evalExpression trueRes meta
  | preppedPred == Just False = evalExpression falseRes meta
  | otherwise = return meta{eval=RUNTIME_ERROR "Ternary operator failed"}
  where preppedPred = maybeEvalTruthy (eval meta)


-- Variable helpers
handleVarDefinition :: TextType -> ID -> META -> IO META
handleVarDefinition iden id meta = do
  case eval meta of
    (RUNTIME_ERROR x) -> return (meta{eval=RUNTIME_ERROR x})
    _ -> do
      newMeta <- addUpdateValueToMeta id meta
      return newMeta{eval=DEC_EVAL iden (eval newMeta) id}