{-# LANGUAGE OverloadedStrings #-}

module EvalMeta where

import ResolverTypes
import Resolver
import qualified Data.Vector as V
import EvalTypes
import AST
import NativeFunctions
import Utils
import qualified Data.HashTable.IO as HT
import qualified Data.Text as T
import Data.Maybe
import Data.List

addNewScopeToClosure :: Closure -> IO Closure
addNewScopeToClosure closure = do
  scope <- HT.new
  return (scope:closure)

deleteScopeFromClosure :: Closure -> Closure
deleteScopeFromClosure closure = newClosure
  where (_:newClosure) = closure

-- Add or Update EVAL on scope
-- We already checked in resolver, so we don't need to do a check if it is there or not
updateScopeInClosure :: T.Text -> EVAL -> Closure -> IO Closure
updateScopeInClosure iden eval closure  = do
  let (last:delClos) = closure
  HT.insert last iden eval
  return (last:delClos)

-- Look up value in the closure, update value
-- We already checked in resolver, so we don't need to do a check if it is there or not
updateInClosure :: T.Text -> EVAL -> Closure -> IO Closure
updateInClosure iden eval closure  = do
  (first, rest) <- partitionClosure iden closure []
  let (last:delClos) = rest
  HT.insert last iden eval
  return (mconcat [first, last:delClos])

-- Find EVAL in scope by its name
getEvalByIden :: T.Text -> Scope -> IO (Maybe EVAL)
getEvalByIden iden scope = HT.lookup scope iden

-- IMPROVE: I think this partition can be a one-liner, not sure
partitionClosure :: TextType -> Closure -> Closure -> IO (Closure, Closure)
partitionClosure iden (h:rest) first = do
  isFound <- isJust <$> getEvalByIden iden h
  if isFound then do
    return (first,h:rest)
  else do
    let newFirst = (h:first)
    partitionClosure iden rest newFirst
partitionClosure iden [] first = return (first, [])


-- META
-- variableValues: indexed values' EVAL are saved here
data META = META {
-- indexed values' EVAL are saved here
  variableValues :: V.Vector EVAL
-- closure variables' EVAL are saved here
  , closure :: Closure
-- The evaluated value
  , eval :: EVAL
-- If the last eval was inside a return function (it's a helper for functions to know they should stop evaluating the remaining declarations)
  , isReturn :: Bool
-- superClass, this is for saving the values of called "super.init".
-- When we call a subClasses "init" function it will call the superclasses "init" function recursively, till we reach a class
-- When the class calls it it can finish its init method and can save its declaration here.
-- Then the subclass which called the class takes out the superclass, saves it in its closure as super
-- and saves itself into this prop, and it goes down till we get to the leaf child class
  , superClass :: EVAL
                 } deriving Show


createGlobalMeta ::  V.Vector EVAL -> IO META
createGlobalMeta vector = do
  return META { variableValues=vector, EvalMeta.closure=[], eval=SKIP_EVAL, EvalMeta.isReturn=False, superClass=EVAL_NIL }

findIndexedValueInMeta :: ID -> META -> IO EVAL
findIndexedValueInMeta (ID id) meta = return (variableValues meta V.! id)

findValueInClosureInMeta :: T.Text -> META -> IO EVAL
findValueInClosureInMeta iden meta = findValueInClosure iden (EvalMeta.closure meta)

findValueInClosure :: T.Text -> Closure -> IO EVAL
findValueInClosure iden clos = do
  values <- mapM (getEvalByIden iden) clos
  let val = find isJust values
  return (fromJust (fromJust val))

maybeFindValueInClosureInMeta :: T.Text -> META -> IO (Maybe EVAL)
maybeFindValueInClosureInMeta iden meta = maybeFindValueInClosure iden (EvalMeta.closure meta)
    
maybeFindValueInClosure :: T.Text -> Closure -> IO (Maybe EVAL)
maybeFindValueInClosure iden clos = do
  values <- mapM (getEvalByIden iden) clos
  let val = find isJust values
  if isNothing val then do
    return Nothing
  else do
    return (fromJust val)

findParentClass :: TextType -> ID -> META -> IO EVAL
findParentClass iden id meta = do
  if id == NON_ID then do
    findValueInClosureInMeta iden meta
  else do
    findIndexedValueInMeta id meta

addUpdateValueToMeta :: ID -> META -> IO META
addUpdateValueToMeta (ID id) meta = return meta{variableValues=V.update (variableValues meta) (V.singleton (id, eval meta))}

addUpdateValueToMetaWithEval :: ID  -> EVAL -> META -> IO META
addUpdateValueToMetaWithEval (ID id) ev meta = return meta{variableValues=V.update (variableValues meta) (V.singleton (id, ev))}

addUpdateScopeInMeta :: T.Text -> META -> IO META
addUpdateScopeInMeta iden meta = do
  clos <- updateScopeInClosure iden (eval meta) (EvalMeta.closure meta)
  return meta{EvalMeta.closure=clos}

addUpdateClosureInMeta :: T.Text -> META -> IO META
addUpdateClosureInMeta iden meta = do
  clos <- updateInClosure iden (eval meta) (EvalMeta.closure meta)
  return meta{EvalMeta.closure=clos}

addUpdateScopeInMetaWithEval :: T.Text -> EVAL -> META -> IO META
addUpdateScopeInMetaWithEval iden eval meta = do
  clos <- updateScopeInClosure iden eval (EvalMeta.closure meta)
  return meta{EvalMeta.closure=clos}

addUpdateClosureInMetaWithEval :: T.Text -> EVAL -> META -> IO META
addUpdateClosureInMetaWithEval iden eval meta = do
  clos <- updateInClosure iden eval (EvalMeta.closure meta)
  return meta{EvalMeta.closure=clos}

addNewScopeToMeta :: META -> IO META
addNewScopeToMeta meta = do
  clos <- addNewScopeToClosure (EvalMeta.closure meta)
  return meta{EvalMeta.closure=clos}

deleteScopeFromMeta :: META -> IO META
deleteScopeFromMeta meta = do
  let clos = deleteScopeFromClosure (EvalMeta.closure meta)
  return meta{EvalMeta.closure=clos}

addSavedClosure :: Closure -> META -> IO META
addSavedClosure clos meta = return meta{EvalMeta.closure=mconcat [clos, EvalMeta.closure meta]}

deleteSavedClosure :: Int -> META -> IO META
deleteSavedClosure numberOfClos meta = return meta{EvalMeta.closure= drop numberOfClos (EvalMeta.closure meta)}

setReturnToFalse ::  META -> IO META
setReturnToFalse meta = return meta{EvalMeta.isReturn=False}