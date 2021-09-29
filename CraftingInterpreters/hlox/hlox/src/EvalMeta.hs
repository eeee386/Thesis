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

type Scope = HT.BasicHashTable T.Text EVAL

type Closure = Stack Scope

addNewScopeToClosure :: Closure -> IO Closure
addNewScopeToClosure closure = do
  scope <- HT.new
  return (push scope closure)

deleteScopeFromClosure :: Closure -> Closure
deleteScopeFromClosure resEnv = newResEnv
  where (_,newResEnv) = pop resEnv

updateScopeInClosure :: T.Text -> EVAL -> Closure -> IO Closure
updateScopeInClosure iden eval closure  = do
  let (last, delClos) = pop closure
  HT.insert last iden eval
  return (push last delClos)

getEvalByIden :: T.Text -> Scope -> IO (Maybe EVAL)
getEvalByIden iden scope = HT.lookup scope iden


-- META
data META = META {
  isInFunction :: Bool
  , isInLoop :: Bool
  , variableValues :: V.Vector EVAL
  , globalVariableValues :: V.Vector EVAL
  , closure :: Closure
                 } deriving Show


createGlobalMeta ::  V.Vector EVAL -> IO META
createGlobalMeta vector = do
  return META { isInFunction=False, isInLoop=True, variableValues=vector, globalVariableValues=createGlobalVector, closure=createStack }

findValueInMeta :: ID -> META -> IO EVAL
findValueInMeta (LOCAL_ID id) meta = return (variableValues meta V.! id)
findValueInMeta (GLOBAL_ID id) meta = return (globalVariableValues meta V.! id)
findValueInMeta NOT_READY _ = return EVAL_NIL
findValueInMeta PARAM _ = return EVAL_NIL

findValueInFunction :: T.Text -> ID -> META -> IO EVAL
findValueInFunction iden id meta = do
  values <- mapM (getEvalByIden iden) (closure meta)
  let val = find isJust values
  if isJust val then return (fromJust (fromJust val)) else do
     findValueInMeta id meta

addUpdateValueToMeta :: ID -> EVAL -> META -> IO META
addUpdateValueToMeta (LOCAL_ID id) eval meta = return meta{variableValues=V.update (variableValues meta) (V.singleton (id, eval))}

addUpdateScopeInMeta :: T.Text -> EVAL -> META -> IO META
addUpdateScopeInMeta iden eval meta = do
  clos <- updateScopeInClosure iden eval (closure meta)
  return meta{closure=clos}

addNewScopeToMeta :: META -> IO META
addNewScopeToMeta meta = do
  clos <- addNewScopeToClosure (closure meta)
  return meta{closure=clos}