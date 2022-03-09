{-# LANGUAGE OverloadedStrings #-}

module Resolver where

import ResolverTypes
import AST
import Data.Maybe
import Data.HashTable.IO as HT
import Utils
import Data.List.Unique as U

-- Resolver's responsibility: 
-- - In declaration, check if it is not already declared in the scope -> if not create a resolver error
-- - In definition, check if it is declared in the scope, and what want to declare is type friendly (somewhat) -> if not create a resolver error
--     - I only check if variable declaration exists and it is a variable declaration not a function or class declaration
--   Handle function and class declaration
-- - Resolve for and while loop and create a unified "LOOP" type after resolution
-- - Check if "return" is in function body, "this" in class, "super" in subclass, "break" and "continue" in loop
-- - Check if references are referencing existing declaration, and calls are referencing classes/function, and simple reference referencing variables
-- - Check if parameters and method names are unique
-- - Check if super- and subclass do not have the same name in declaration
-- - Check if classes have "init" functions and in subclasses "init" functions call "super.init()"
resolveProgram :: PROGRAM -> IO ResolverMeta
resolveProgram (PROG decs) = createNewMeta >>= resolveDeclarations decs >>= reverseDeclarationsAndErrors

resolveDeclarations :: [DECLARATION] -> ResolverMeta -> IO ResolverMeta
resolveDeclarations [] meta = return meta
resolveDeclarations (x:xs) meta = resolveDeclaration x meta >>= resolveDeclarations xs

resolveDeclaration :: DECLARATION -> ResolverMeta -> IO ResolverMeta 
resolveDeclaration (DEC_VAR x) meta = resolveVarDeclaration x meta
resolveDeclaration (DEC_CLASS x) meta = resolveClassDeclaration x meta
resolveDeclaration (DEC_STMT (BLOCK_STMT x)) meta = resolveBlock x meta
resolveDeclaration (DEC_STMT (RETURN exp)) meta = do
  resMeta <- resolveExpression exp meta
  let resExp = newExpr resMeta
  return (updateResolverErrorsByPredicate (isInFunction meta) "Return is not in function" resMeta{
    declarations=DEC_STMT (RETURN resExp):declarations meta
})
resolveDeclaration (DEC_FUNC x) meta = resolveFunctionDeclaration x meta
resolveDeclaration (DEC_STMT (WHILE_STMT exp (BLOCK_STMT decs))) meta = do
  resMeta <- resolveExpression exp meta
  let resExp = newExpr resMeta
  resBlockMeta <- resolveBlock decs resMeta{declarations=[], isInLoop=True}
  let (DEC_STMT resBlockStmt) = head (declarations resBlockMeta)
  return resBlockMeta{declarations=DEC_STMT (LOOP resExp resBlockStmt):declarations meta, isInLoop=isInLoop meta}
resolveDeclaration (DEC_STMT (FOR_STMT (DEC_VAR varDec) exp1 varAss (BLOCK_STMT decs))) meta = do
  varMeta <- resolveVarDeclaration varDec meta
  resExpMeta <- resolveExpression exp1 varMeta
  let resExp = newExpr resExpMeta
  resBlockMeta <- resolveBlock ((reverse . (:) varAss . reverse) decs ) resExpMeta{declarations=[], isInLoop=True}
  let (DEC_STMT resBlockStmt) = head (declarations resBlockMeta)
  return resBlockMeta{declarations=DEC_STMT (LOOP resExp resBlockStmt):declarations varMeta, isInLoop=isInLoop meta}
resolveDeclaration (DEC_STMT (IF_STMT exp (BLOCK_STMT decs))) meta = do
  resMeta <- resolveExpression exp meta
  let resExp = newExpr resMeta
  resBlockMeta <- resolveBlock decs resMeta{declarations=[]}
  let (DEC_STMT resBlockStmt) = head (declarations resBlockMeta)
  return resBlockMeta{declarations=DEC_STMT (IF_STMT resExp resBlockStmt):declarations meta}
resolveDeclaration (DEC_STMT (IF_ELSE_STMT exp (BLOCK_STMT ifdecs) (BLOCK_STMT elsedecs))) meta = do
  resMeta <- resolveExpression exp meta
  let resExp = newExpr resMeta
  resIfBlockMeta <- resolveBlock ifdecs resMeta{declarations=[]}
  let (DEC_STMT resIfBlockStmt) = head (declarations resIfBlockMeta)
  resElseBlockMeta <- resolveBlock elsedecs resIfBlockMeta{declarations=[]}
  let (DEC_STMT resElseBlockStmt) = head (declarations resElseBlockMeta)
  return resElseBlockMeta{declarations=DEC_STMT (IF_ELSE_STMT resExp resIfBlockStmt resElseBlockStmt):declarations meta}
resolveDeclaration (DEC_STMT BREAK) meta =  return (updateResolverErrorsByPredicate (isInLoop meta) "The 'break' statement should be inside a loop" meta{declarations=DEC_STMT BREAK:declarations meta})
resolveDeclaration (DEC_STMT CONTINUE) meta =  return (updateResolverErrorsByPredicate (isInLoop meta) "The 'continue' statement should be inside a loop" meta{declarations=DEC_STMT CONTINUE:declarations meta})
resolveDeclaration (DEC_STMT (PRINT_STMT x)) meta = do 
  expMeta <- resolveExpression x meta
  return expMeta{declarations=DEC_STMT (PRINT_STMT (newExpr expMeta)):declarations expMeta} 
resolveDeclaration (DEC_STMT (EXPR_STMT x)) meta = do 
  expMeta <- resolveExpression x meta
  return expMeta{declarations=DEC_STMT (EXPR_STMT (newExpr expMeta)):declarations expMeta} 
resolveDeclaration EMPTY_DEC meta = return meta
resolveDeclaration x meta = return meta{declarations=x:declarations meta}

resolveVarDeclaration :: VARIABLE_DECLARATION -> ResolverMeta -> IO ResolverMeta
resolveVarDeclaration (VAR_DEC_DEF iden exp) meta = resolveExpression exp meta >>= checkIfDefinedForDeclarationAndDefinition iden (\exp id -> R_DEC_VAR (R_VAR_DEC_DEF iden exp id)) (R_DEC_VAR . RC_VAR_DEC_DEF iden)
resolveVarDeclaration (VAR_DEC iden) meta = checkIfDefinedForDeclaration iden (R_DEC_VAR . R_VAR_DEC iden) (R_DEC_VAR (RC_VAR_DEC iden)) meta
resolveVarDeclaration (VAR_DEF iden exp) meta = resolveExpression exp meta >>= checkIfDefinedForDefinitionWithExpr iden (\exp id -> R_DEC_VAR (R_VAR_DEF iden exp id)) (R_DEC_VAR . RC_VAR_DEF iden)
resolveVarDeclaration (CLASS_VAR_DEF iden pIden exp) meta = resolveExpression exp meta >>= checkIfDefinedForDefinitionWithExpr iden (\exp id -> R_DEC_VAR (R_CLASS_VAR_DEF iden pIden exp id)) (R_DEC_VAR . RC_CLASS_VAR_DEF iden pIden)
resolveVarDeclaration (THIS_VAR_DEF iden exp) meta = do
  exprMeta <- resolveExpression exp meta
  return (updateResolverErrorsByPredicate (isInClass meta) "'this' is called outside of class" exprMeta{declarations=R_DEC_VAR (R_THIS_VAR_DEF iden (newExpr exprMeta)):declarations meta})

-- Check if method is resolved properly
resolveFunctionDeclaration :: FUNCTION_DECLARATION -> ResolverMeta -> IO ResolverMeta
resolveFunctionDeclaration (FUNC_DEC iden params (BLOCK_STMT decs)) meta = resolveFunctionDeclarationHelper iden params decs functionMetaChanger meta
resolveFunctionDeclaration (METHOD_DEC iden params (BLOCK_STMT decs)) meta = resolveFunctionDeclarationHelper iden params decs methodMetaChanger meta

resolveFunctionDeclarationHelper :: TextType -> [DECLARATION] -> [DECLARATION] -> (ID -> TextType -> [DECLARATION] -> ResolverMeta -> ResolverMeta -> IO ResolverMeta) -> ResolverMeta -> IO ResolverMeta
resolveFunctionDeclarationHelper iden params decs changer meta = do
  (id, savedMeta) <- checkIfFunctionOrClassIsDefinedAndSaveEmpty iden meta
  newBlockMeta <- addBlockToMeta savedMeta{currentFunctionName=iden} >>= addClosureToMeta
  let isUniqueParamNames = U.allUnique (map getIdentifierFromParams params)
  updatedParams <- handleParams params newBlockMeta
  newMeta <- resolveDeclarations decs (updateResolverErrorsByPredicate isUniqueParamNames "Parameter names are not unique" (updatedParams{
                                       isInFunction = True
                                       , declarations=[]
  })) >>= reverseDeclarationsAndErrors
  deleteBlockFromMeta newMeta{currentFunctionName=""} >>= deleteClosureFromMeta >>= changer id iden params meta

functionMetaChanger :: ID -> TextType -> [DECLARATION] -> ResolverMeta -> ResolverMeta -> IO ResolverMeta
functionMetaChanger id iden params meta newMeta = updateFunctionOrClassDeclaration id iden dec newMeta{isInFunction = isInFunction meta, resolverErrors=resolverErrors newMeta, declarations=declarations meta}
  where dec = if isInFunction meta then DEC_FUNC (RC_FUNC_DEC iden params (BLOCK_STMT (declarations newMeta))) else DEC_FUNC (R_FUNC_DEC iden params (BLOCK_STMT (declarations newMeta)) id)
    
methodMetaChanger :: ID -> TextType -> [DECLARATION] -> ResolverMeta -> ResolverMeta -> IO ResolverMeta
methodMetaChanger id iden params meta newMeta = return newMeta{isInFunction = isInFunction meta, declarations=DEC_FUNC (METHOD_DEC iden params (BLOCK_STMT (declarations newMeta))):declarations meta}

resolveClassDeclaration :: CLASS_DECLARATION -> ResolverMeta -> IO ResolverMeta
resolveClassDeclaration (CLASS_DEC iden methods) meta = do
  (id, updatedMeta) <- checkIfFunctionOrClassIsDefinedAndSaveEmpty iden meta
  newMeta <- handleClassSetup methods updatedMeta{isInClass=True}
  let newMethods = declarations newMeta
  if isInFunctionOrClass meta then do
    handleSaveClassDec id iden (R_DEC_CLASS (RC_CLASS_DEC iden newMethods)) meta newMeta
  else do
    handleSaveClassDec id iden (R_DEC_CLASS (R_CLASS_DEC iden newMethods id)) meta newMeta
      
resolveClassDeclaration (SUB_CLASS_DEC iden parentIden methods) meta = do
  let cMeta = updateResolverErrorsByPredicate (iden == parentIden) "Class name cannot be parent class name" meta
  (id, updatedMeta) <- checkIfFunctionOrClassIsDefinedAndSaveEmpty iden meta
  newMeta <- handleClassSetup methods updatedMeta{isInClass=True, isInSubClass=True}
  let newMethods = declarations newMeta
  if isInFunctionOrClass meta then do
    inClosure <- isInClosure parentIden meta
    if inClosure then do
      handleSaveClassDec id iden (R_DEC_CLASS (RC_SUB_CLASS_DEC iden parentIden newMethods NON_ID)) meta newMeta
    else do
      maybeParentIdVal <- findIdInVariables parentIden newMeta
      let maybeParentId = ID <$> maybeParentIdVal
      handleSaveClassDec id iden (R_DEC_CLASS (RC_SUB_CLASS_DEC iden parentIden newMethods (fromMaybe NON_ID maybeParentId))) meta (parentNotInScopeError maybeParentId newMeta)
  else do
    maybeParentIdVal <- findIdInVariables parentIden newMeta
    let maybeParentId = ID <$> maybeParentIdVal
    handleSaveClassDec id iden (R_DEC_CLASS (R_SUB_CLASS_DEC iden parentIden newMethods id (fromMaybe NON_ID maybeParentId))) meta (parentNotInScopeError maybeParentId newMeta)
    
parentNotInScopeError :: Maybe ID -> ResolverMeta -> ResolverMeta
parentNotInScopeError maybeParentId = updateResolverErrorsByPredicate (isJust maybeParentId) "Parent class is not in scope"

handleSaveClassDec :: ID -> TextType -> DECLARATION -> ResolverMeta -> ResolverMeta -> IO ResolverMeta
handleSaveClassDec id iden dec oldMeta meta = deleteBlockFromMeta meta{isInClass=isInClass oldMeta, isInSubClass=isInSubClass oldMeta, declarations=declarations oldMeta} >>= updateFunctionOrClassDeclaration id iden dec

handleClassSetup :: [DECLARATION] -> ResolverMeta -> IO ResolverMeta
handleClassSetup methods meta = addBlockToMeta meta >>= addClosureToMeta >>= resolveMethods methods

-- I will force that "init" is required, because creating init on the fly is easy for simple classes, but when it comes to subclasses,
-- what happens if the superclass init has args -> 
-- 1. you can create an init to have the same number of arguments (confusing)
-- 2. You add default args to super -> hard to create, confusing for users
-- 3. force it -> easy to check, transparent to users, albeit tedious
resolveMethods :: [DECLARATION] -> ResolverMeta -> IO ResolverMeta
resolveMethods methods meta = do
 let isUniqueMethodNames = U.allUnique (map getIdentifierFromMethod methods)
 let hasInit = any (\method -> getIdentifierFromMethod method == "init") methods
 let isSuperError = not (isInSubClass meta) || hasSuperInitInInit methods
 resolveDeclarations methods (
   updateResolverErrorsByPredicate hasInit "Class does not have init" (
   updateResolverErrorsByPredicate isSuperError "Subclass does not have super.init in init function" (
   updateResolverErrorsByPredicate isUniqueMethodNames "Method names are not unique" meta{
   declarations=[]
 }))) >>= reverseDeclarationsAndErrors

resolveBlock :: [DECLARATION] -> ResolverMeta -> IO ResolverMeta
resolveBlock decs meta = do
  newMeta <- addBlockToMeta meta{declarations=[]} >>= resolveDeclarations decs >>= reverseDeclarationsAndErrors
  deleteBlockFromMeta (newMeta{declarations=DEC_STMT (BLOCK_STMT (declarations newMeta)):declarations meta})

-- Declarations are a series of declaration, but expressions are trees
-- Practically what I do here is I handle the leaf nodes and save them in the "newExpr" property in the meta object.
-- For inner or root node I call the "resolveExpression" on the children, get the results from "newExpr" property,
-- and using those, create the resolved inner/root expression, and save it to the meta "newExpr" property
resolveExpression :: EXPRESSION -> ResolverMeta -> IO ResolverMeta
resolveExpression (EXP_LITERAL (IDENTIFIER_REFERENCE iden)) meta = checkIfReferenceForDefinition iden (EXP_LITERAL . R_IDENTIFIER_REFERENCE iden) (EXP_LITERAL (R_REFERENCE_IN_CLOSURE iden)) meta
resolveExpression (EXP_LITERAL x) meta = return meta{newExpr= EXP_LITERAL x}
resolveExpression (EXP_UNARY (UNARY_NEGATE exp)) meta = handleUnary UNARY_NEGATE exp meta
resolveExpression (EXP_UNARY (UNARY_MINUS exp)) meta = handleUnary UNARY_MINUS exp meta
resolveExpression (EXP_GROUPING (GROUP exp)) meta = handleGrouping GROUP exp meta
resolveExpression (EXP_BINARY (BIN_ADD left right)) meta = handleBinaryExp BIN_ADD left right meta 
resolveExpression (EXP_BINARY (BIN_SUB left right)) meta = handleBinaryExp BIN_SUB left right meta 
resolveExpression (EXP_BINARY (BIN_MUL left right)) meta = handleBinaryExp BIN_MUL left right meta 
resolveExpression (EXP_BINARY (BIN_DIV left right)) meta = handleBinaryExp BIN_DIV left right meta 
resolveExpression (EXP_BINARY (BIN_EQ left right)) meta = handleBinaryExp BIN_EQ left right meta 
resolveExpression (EXP_BINARY (BIN_NOT_EQ left right)) meta = handleBinaryExp BIN_NOT_EQ left right meta 
resolveExpression (EXP_BINARY (BIN_COMP_LESS left right)) meta = handleBinaryExp BIN_COMP_LESS left right meta 
resolveExpression (EXP_BINARY (BIN_COMP_LESS_EQ left right)) meta = handleBinaryExp BIN_COMP_LESS_EQ left right meta 
resolveExpression (EXP_BINARY (BIN_COMP_GREATER left right)) meta = handleBinaryExp BIN_COMP_GREATER left right meta 
resolveExpression (EXP_BINARY (BIN_COMP_GREATER_EQ left right)) meta = handleBinaryExp BIN_COMP_GREATER_EQ left right meta 
resolveExpression (EXP_BINARY (BIN_AND left right)) meta = handleBinaryExp BIN_AND left right meta 
resolveExpression (EXP_BINARY (BIN_OR left right)) meta = handleBinaryExp BIN_OR left right meta 
resolveExpression (EXP_TERNARY (TERNARY pred tExp fExp)) meta = do
  predMeta <- resolveExpression pred meta
  let predExpr = newExpr predMeta
  trueMeta <- resolveExpression tExp predMeta
  let trueExpr = newExpr trueMeta
  falseMeta <- resolveExpression fExp trueMeta
  let falseExpr = newExpr falseMeta
  return falseMeta{newExpr= EXP_TERNARY (TERNARY predExpr trueExpr falseExpr) }
resolveExpression (EXP_CALL (CALL iden args)) meta = handleCall iden args meta
-- Recursive type CALL_MULTI can have other CALL_MULTI in them
-- And it will call it recursively till we find a CALL
resolveExpression (EXP_CALL (CALL_MULTI call multiArgs)) meta = do
  (resolvedArgs, newResErrs) <- handleArguments multiArgs meta
  (EXP_CALL newCall) <- newExpr <$> resolveExpression (EXP_CALL call) meta
  return meta{
    newExpr=EXP_CALL (CALL_MULTI newCall resolvedArgs)
    , resolverErrors=mconcat [newResErrs, resolverErrors meta]
  }
-- Here I only check the first link, as it is the one that could be anything.
-- The other links should be some property on the class referenced, or returned
resolveExpression (EXP_CHAIN (CHAIN links)) meta = do
  let (firstLink:rest) = links
  case firstLink of
    (LINK_CALL firstCall) -> do
      callMeta <- resolveExpression (EXP_CALL firstCall) meta
      let (EXP_CALL x) = newExpr callMeta
      return meta{newExpr=EXP_CHAIN (CHAIN (LINK_CALL x:rest))}
    (LINK_IDENTIFIER iden) -> do 
      newMeta <- checkIfReferenceForDefinition iden (\p -> EXP_CHAIN (CHAIN [R_LINK_IDENTIFIER iden p])) (EXP_CHAIN (CHAIN [RC_LINK_IDENTIFIER iden])) meta
      let (EXP_CHAIN (CHAIN (x:_))) = newExpr newMeta
      return newMeta{newExpr=EXP_CHAIN (CHAIN (x:rest))}
    LINK_THIS -> return (updateResolverErrorsByPredicate (isInClass meta) "The 'this' keyword has to be called in a class" meta{newExpr=EXP_CHAIN (CHAIN links)})
    LINK_SUPER -> return (updateResolverErrorsByPredicate (isInClass meta) "The 'super' keyword has to be called in a subclass" meta{newExpr=EXP_CHAIN (CHAIN links)})
    _ -> return meta{newExpr=EXP_CHAIN (CHAIN links)}

resolveExpression EXP_THIS meta = return (updateResolverErrorsByPredicate (isInClass meta) "The 'this' keyword has to be called in a class" meta{newExpr=EXP_THIS})
resolveExpression exp meta = return meta{newExpr=exp}


handleUnary :: (EXPRESSION -> UNARY) -> EXPRESSION -> ResolverMeta -> IO ResolverMeta
handleUnary fact = handleSingleExp (EXP_UNARY . fact)

handleGrouping :: (EXPRESSION -> GROUPING) -> EXPRESSION -> ResolverMeta -> IO ResolverMeta
handleGrouping fact = handleSingleExp (EXP_GROUPING . fact)

handleSingleExp :: (EXPRESSION -> EXPRESSION) -> EXPRESSION -> ResolverMeta -> IO ResolverMeta
handleSingleExp fact exp meta = do
  newMeta <- resolveExpression exp meta
  return newMeta{newExpr=fact (newExpr newMeta) }

handleBinaryExp :: (EXPRESSION -> EXPRESSION -> BINARY) -> EXPRESSION -> EXPRESSION -> ResolverMeta -> IO ResolverMeta
handleBinaryExp fact left right meta = do
  leftMeta <- resolveExpression left meta
  let leftExpr = newExpr leftMeta
  rightMeta <- resolveExpression right leftMeta
  let rightExpr = newExpr rightMeta
  return rightMeta{newExpr=EXP_BINARY (fact leftExpr rightExpr) }

-- TODO: add check that it really calls a function, and relagate the arity check here
handleCall :: TextType -> [ARGUMENT] -> ResolverMeta -> IO ResolverMeta
handleCall iden args meta = do
  (newArgs, newResErrs) <- handleArguments args meta
  checkIfCallReferenceForDefinition iden (EXP_CALL . R_CALL iden newArgs) (EXP_CALL (RC_CALL iden newArgs)) meta{resolverErrors=mconcat [newResErrs, resolverErrors meta]}

-- I resolve the arguments one by one (trees where the roots are next to each other)
-- And then I combine them and to get the resolved expression, and all the errors, and send it back to the caller
handleArguments :: [ARGUMENT] -> ResolverMeta -> IO ([ARGUMENT], [TextType])
handleArguments args meta = do
    newMetas <- mapM (`resolveExpression` meta{resolverErrors=[]}) args
    let newArgs = map newExpr newMetas
    let newResolverErrors = mconcat (map resolverErrors newMetas)
    return (newArgs, newResolverErrors)

-- I save the params into the functions' resolver closure
-- Order does not really matter, because we will only use this for resolution
handleParams :: [DECLARATION] -> ResolverMeta -> IO ResolverMeta
handleParams (p:params) meta = do
   let (DEC_VAR (PARAM iden)) = p
   newClosure <- updateClosure iden p (closure meta)
   handleParams params meta{closure=newClosure}
handleParams [] meta = return meta

hasSuperInitInInit :: [DECLARATION] -> Bool
hasSuperInitInInit methods =  hasSuperInit (head (filter (not . null) (map getInitFromMethods methods)))
  where getInitFromMethods (DEC_FUNC (METHOD_DEC "init" _ (BLOCK_STMT decs))) = decs
        getInitFromMethods _ = []

hasSuperInit :: [DECLARATION] -> Bool
hasSuperInit = any isSuperInit

isSuperInit :: DECLARATION -> Bool
isSuperInit (DEC_STMT (EXPR_STMT (EXP_CHAIN (CHAIN [LINK_SUPER,LINK_CALL (CALL "init" _)])))) = True
isSuperInit _ = False