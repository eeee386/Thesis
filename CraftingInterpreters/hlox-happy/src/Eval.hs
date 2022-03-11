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
import NativeFunctionTypes

evalProgram :: [DECLARATION] -> V.Vector EVAL -> IO META
evalProgram x vector = createGlobalMeta vector >>= evalDeclarations x

evalBlock :: [DECLARATION]  -> META -> IO META
evalBlock = evalDeclarations

-- We only care about the last eval
-- if return stop evaluating the declarations (function body), and return the return eval's eval
-- if continue or break stop evaluation
-- RUNTIME_ERROR -> print then stop evaluating the declarations return meta
-- IMPROVE: Runtime error is written twice, if it is in function body
evalDeclarations :: [DECLARATION] -> META -> IO META
evalDeclarations decs meta
  | L.null decs || EvalMeta.isReturn meta = return meta
  | otherwise = do
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
  return newMeta{eval=EVAL_NIL}
evalDeclaration (DEC_STMT (EXPR_STMT x)) meta = evalExpression x meta

evalDeclaration (DEC_STMT BREAK) meta = return meta{eval=BREAK_EVAL}
evalDeclaration (DEC_STMT CONTINUE) meta = return meta{eval=CONTINUE_EVAL}

-- Indexed variables
-- Evaluate expression -> it is saved in "eval" prop of "meta"
-- R_VAR_DEC_DEF/R_VAR_DEF:handleIndexedVarDefinition -> check if last eval (expression eval) was runtimeerror -> if not save value to variableVector else return runtimeerror
-- R_VAR_DEC -> we already resolved it, just add eval to meta
-- R_CLASS_VAR_DEF -> save value to closure/update value in closure
evalDeclaration (R_DEC_VAR (R_VAR_DEC_DEF iden expr id)) meta = evalExpression expr meta >>= handleIndexedVarDefinition iden id
evalDeclaration (R_DEC_VAR (R_VAR_DEC iden id)) meta = return meta{eval=DEC_EVAL iden EVAL_NIL id}
evalDeclaration (R_DEC_VAR (R_VAR_DEF iden expr id)) meta = evalExpression expr meta >>= handleIndexedVarDefinition iden id
evalDeclaration (R_DEC_VAR (R_CLASS_VAR_DEF iden pIden expr classId)) meta = do
    classEval <- findIndexedValueInMeta classId meta
    let evalClassDec newMeta = case classEval of
          (CLASS_DEC_EVAL name evals clos id) -> do
            newClos <- updateScopeInClosure pIden (eval newMeta) clos
            addUpdateValueToMeta id newMeta{eval=CLASS_DEC_EVAL name evals newClos id}
          (SUB_CLASS_DEC_EVAL name parentName evals clos id parentId) -> do
            newClos <- updateScopeInClosure pIden (eval newMeta) clos
            addUpdateValueToMeta id newMeta{eval=SUB_CLASS_DEC_EVAL name parentName evals newClos id parentId}
          _ -> return newMeta{eval=RUNTIME_ERROR "Unknown error"}
    evalExpression expr meta >>= checkIfLastEvalIsRuntimeError evalClassDec
-- Closure variables
-- RC_VAR_DEC_DEF: handleVarDefinition -> if evaluated expression is runtimeerror then return runtimeerror else add iden with evaluated expression to scope
-- RC_VAR_DEC: save iden to scope
-- RC_VAR_DEC_DEF: handleVarDefinition -> if evaluated expression is runtimeerror then return runtimeerror else find iden in closure and update its value with evaluated expression
-- RC_THIS_VAR_DEF: if evaluated expression is runtimeerror then return runtimeerror else find "this" in closure find iden in closure and update its value with evaluated expression
evalDeclaration (R_DEC_VAR (RC_VAR_DEC_DEF iden expr)) meta = evalExpression expr meta >>= handleVarDefinition (\ev -> DEC_EVAL iden ev NON_ID) (addUpdateScopeInMeta iden)
evalDeclaration (R_DEC_VAR (RC_VAR_DEC iden)) meta = addUpdateScopeInMeta iden meta{eval=EVAL_NIL}
evalDeclaration (R_DEC_VAR (RC_VAR_DEF iden expr)) meta = evalExpression expr meta >>= handleVarDefinition (\ev -> DEC_EVAL iden ev NON_ID) (addUpdateClosureInMeta iden)
evalDeclaration (R_DEC_VAR (RC_THIS_VAR_DEF iden expr)) meta = checkIfLastEvalIsRuntimeError func meta
  where func pMeta = do
              exprMeta <- evalExpression expr pMeta
              let exprEval = eval exprMeta
              classEval <- findValueInClosureInMeta "this" exprMeta
              case classEval of
                (CLASS_DEC_EVAL classIden decs clos id) -> do
                  newClos <- updateScopeInClosure iden exprEval clos
                  addUpdateClosureInMetaWithEval "this" (CLASS_DEC_EVAL classIden decs newClos id) exprMeta
                (SUB_CLASS_DEC_EVAL classIden parentIden decs clos id parentId ) -> do
                  newClos <- updateScopeInClosure iden exprEval clos
                  addUpdateClosureInMetaWithEval "this" (SUB_CLASS_DEC_EVAL classIden parentIden decs newClos id parentId) exprMeta


evalDeclaration (DEC_STMT (BLOCK_STMT x)) meta = evalBlock x meta
-- Evaluate expression -> if expression runtime error then return runtime error else 
-- check if expression truthy value if truthy evaluate block else just return the original meta  
evalDeclaration (DEC_STMT (IF_STMT expr stmt)) meta = evalExpression expr meta >>= checkIfLastEvalIsRuntimeError evalIf
  where evalIf newMeta = if maybeEvalTruthy (eval newMeta) == Just True then do
                           evalDeclaration (createDecFromStatement stmt) newMeta
                         else return newMeta
-- Evaluate expression -> if expression runtime error then return runtime error else 
-- check if expression truthy value if truthy evaluate first block else evaluate second block
evalDeclaration (DEC_STMT (IF_ELSE_STMT expr stmt1 stmt2)) meta = evalExpression expr meta >>= checkIfLastEvalIsRuntimeError evalIfElse
  where evalIfElse newMeta = if maybeEvalTruthy (eval newMeta) == Just True then evalDeclaration (createDecFromStatement stmt1) newMeta else evalDeclaration (createDecFromStatement stmt2) newMeta
-- Evaluate expression -> if expression runtime error then return runtime error else 
-- while expression truthy value or was not a break or runtimeerror in last evaluation of the block then eval block else return original meta  
evalDeclaration (DEC_STMT (LOOP expr stmt)) meta = evalExpression expr meta >>= checkIfLastEvalIsRuntimeError evalLoop
  where lastEval = eval meta
        evalLoop newMeta = if maybeEvalTruthy (eval newMeta) == Just True && not (isBreak lastEval) && not (isRuntimeError lastEval) then do
                             evalDeclaration (createDecFromStatement stmt) newMeta >>= evalDeclaration (DEC_STMT (LOOP expr stmt))
                           else do
                             return newMeta

-- Creating the function/class eval from the declaration, then saving it to either closure or variableVector
evalDeclaration (DEC_FUNC (R_FUNC_DEC iden params stmt id)) meta = functionDecEvalHelper (addUpdateValueToMeta id) iden params stmt id meta
evalDeclaration (DEC_FUNC (RC_FUNC_DEC iden params stmt)) meta = functionDecEvalHelper (addUpdateScopeInMeta iden) iden params stmt NON_ID meta
evalDeclaration (DEC_FUNC (METHOD_DEC iden params stmt)) meta = functionDecEvalHelper (addUpdateScopeInMeta iden) iden params stmt NON_ID meta
-- closure meta will be an empty list, when creating so it could be an [] as well
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
-- Get value from closure or variableVector
evalExpression (EXP_LITERAL (R_IDENTIFIER_REFERENCE _ id)) meta = do
  val <- findIndexedValueInMeta id meta
  return meta{eval=val}
evalExpression (EXP_LITERAL (RC_IDENTIFIER_REFERENCE iden)) meta = do
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
-- Call
evalExpression (EXP_CALL (CALL call_iden args)) meta = handleCallEval args (findValueInClosureInMeta call_iden) meta
evalExpression (EXP_CALL (R_CALL _ args id)) meta = handleCallEval args (findIndexedValueInMeta id) meta
evalExpression (EXP_CALL (RC_CALL call_iden args)) meta = handleCallEval args (findValueInClosureInMeta call_iden) meta
evalExpression (EXP_CALL (CALL_MULTI call args)) meta = evalExpression (EXP_CALL call) meta >>= handleCallEval args multiCallGetFunc

-- handling "super.init" call
evalExpression (EXP_CHAIN (CHAIN [LINK_SUPER,LINK_CALL (CALL "init" args)])) meta = do
  (SUB_CLASS_DEC_EVAL _ parentName _ _ _ parentId) <- findValueInClosureInMeta "this" meta
  parentClassEval <- findParentClass parentName parentId meta
  newMeta <- evalInit args parentClassEval meta
  return meta{superClass=eval newMeta}


evalExpression (EXP_CHAIN (CHAIN (l:links))) meta = do
  case l of
    LINK_THIS -> do
      classEval <- findValueInClosureInMeta "this" meta
      evalExpression (EXP_CHAIN (CHAIN links)) meta{eval=classEval}
    LINK_SUPER -> do
      parentClassEval <- findValueInClosureInMeta "super" meta
      evalExpression (EXP_CHAIN (CHAIN links)) meta{eval=parentClassEval}
    LINK_CALL x -> do
      case eval meta of
        (CLASS_DEC_EVAL _ _ clos _) -> handleChainCall l links clos meta
        (SUB_CLASS_DEC_EVAL _ _ _ clos _ _) -> handleSubClassChain l links clos handleChainCall meta
        _ -> handleChainCall l links (closure meta) meta
    -- Link Identifier is the ending of the chain
    (LINK_IDENTIFIER x) -> do
      case eval meta of
        (CLASS_DEC_EVAL _ _ clos _) -> handleChainIdentifier l links clos meta
        (SUB_CLASS_DEC_EVAL _ _ _ clos _ _) -> handleSubClassChain l links clos handleChainIdentifier meta
        _ -> return meta{eval=RUNTIME_ERROR "Dot operation is only permitted on classes"}
    (R_LINK_IDENTIFIER _ id) -> do
      ev <- findIndexedValueInMeta id meta
      evalExpression (EXP_CHAIN (CHAIN links)) meta{eval=ev}
    (RC_LINK_IDENTIFIER iden) -> do 
      ev <- findValueInClosureInMeta iden meta
      evalExpression (EXP_CHAIN (CHAIN links)) meta{eval=ev}
evalExpression (EXP_CHAIN (CHAIN [])) meta = return meta

evalExpression EXP_THIS meta = do
  ev <- findValueInClosureInMeta "this" meta
  return meta{eval=ev}
evalExpression exp meta = do
  return meta{eval=RUNTIME_ERROR "Expression cannot be evaluated"}

handleSubClassChain :: CHAIN_LINK -> [CHAIN_LINK] -> Closure -> (CHAIN_LINK -> [CHAIN_LINK] -> Closure -> META -> IO META) -> META -> IO META
handleSubClassChain l links clos func meta = do
  parentClassEval <- findValueInClosure "super" clos
  case parentClassEval of
    (CLASS_DEC_EVAL _ _ parentClos _) -> func l links (mconcat [clos, parentClos]) meta
    (SUB_CLASS_DEC_EVAL _ _ _ parentClos _ _) -> do
      newClos <- getAllClosuresFromInheritance clos parentClos
      func l links newClos meta

getAllClosuresFromInheritance :: Closure -> Closure -> IO Closure
getAllClosuresFromInheritance clos pClos = do
  parentClassEval <- findValueInClosure "super" pClos
  let newClos = mconcat [clos, pClos]
  case parentClassEval of
    (CLASS_DEC_EVAL _ _ parentClos _) -> return (mconcat [newClos, parentClos])
    (SUB_CLASS_DEC_EVAL _ _ _ parentClos _ _) -> getAllClosuresFromInheritance newClos parentClos




handleCallEval :: [ARGUMENT] -> (META -> IO EVAL) -> META -> IO META
handleCallEval args findDec meta = do
  ev <- findDec meta
  case ev of 
    FUNC_DEC_EVAL {} -> handleFunctionCall args ev meta
    NATIVE_FUNC_DEC_EVAL {} -> handleNativeFunctionCall args ev meta 
    CLASS_DEC_EVAL {} -> evalInit args ev meta
    SUB_CLASS_DEC_EVAL {} -> evalInit args ev meta
    _ -> return meta{eval=RUNTIME_ERROR "Self recursive function name overwritten in block"}
  
evalInit :: [ARGUMENT]  -> EVAL -> META -> IO META
evalInit args classEval meta = do
  case classEval of
    (CLASS_DEC_EVAL iden decs _ id) -> do
      let fact = (\clos -> CLASS_DEC_EVAL iden decs clos id)
      let func initMeta = return initMeta
      handleInit args decs fact func meta
    (SUB_CLASS_DEC_EVAL iden pIden decs _ id pId) -> do
      let fact = (\clos -> SUB_CLASS_DEC_EVAL iden pIden decs clos id pId)      
      handleInit args decs fact addSuperToClosure meta

addSuperToClosure :: META -> IO META
addSuperToClosure initMeta = do
  let parentClass = superClass initMeta
  superMeta <- addUpdateScopeInMetaWithEval "super" parentClass initMeta
  return superMeta{superClass=EVAL_NIL}
  
 
handleInit :: [ARGUMENT] -> [DECLARATION] -> (Closure -> EVAL) -> (META -> IO META) -> META -> IO META
handleInit args decs fact func meta = do
  newMeta <- addNewScopeToMeta meta >>= handleMethodsEval decs
  -- Class's this declaration will not have this in it but the parser already filters out "this.this/super.this" structure
  thisMeta <- addUpdateScopeInMetaWithEval "this" (fact (closure newMeta)) newMeta
  init <- findValueInClosureInMeta "init" thisMeta
  initMeta <- handleFunctionCall args init thisMeta
  additionalMeta <- func initMeta
  deleteScopeFromMeta additionalMeta{eval=fact (closure additionalMeta)}


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

handleNativeFunctionCall :: [ARGUMENT] -> EVAL -> META -> IO META 
handleNativeFunctionCall _ (NATIVE_FUNC_DEC_EVAL _ _ _ (CLOCK clock)) meta = do
  val <- clock id
  return meta{eval=EVAL_NUMBER (fromInteger val)}
  
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
handleIndexedVarDefinition :: TextType -> ID -> META -> IO META
handleIndexedVarDefinition iden id = handleVarDefinition (\ev -> DEC_EVAL iden ev id) (addUpdateValueToMeta id)
      
handleVarDefinition :: (EVAL -> EVAL) -> (META -> IO META) -> META -> IO META
handleVarDefinition ev saveFunc meta = do
  case eval meta of
    (RUNTIME_ERROR x) -> return (meta{eval=RUNTIME_ERROR x})
    _ -> do
      newMeta <- saveFunc meta
      return newMeta{eval=ev (eval meta)}
      
 