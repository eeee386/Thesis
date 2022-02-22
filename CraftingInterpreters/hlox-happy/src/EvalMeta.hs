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

updateScopeInClosure :: T.Text -> EVAL -> Closure -> IO Closure
updateScopeInClosure iden eval closure  = do
  let (last:delClos) = closure
  HT.insert last iden eval
  return (last:delClos)

getEvalByIden :: T.Text -> Scope -> IO (Maybe EVAL)
getEvalByIden iden scope = HT.lookup scope iden


-- META
data META = META {
  variableValues :: V.Vector EVAL
  , closure :: Closure
  , eval :: EVAL
                 } deriving Show


createGlobalMeta ::  V.Vector EVAL -> IO META
createGlobalMeta vector = do
  return META { variableValues=vector, EvalMeta.closure=[], eval=SKIP_EVAL }

findValueInMeta :: ID -> META -> IO EVAL
findValueInMeta id meta = return (variableValues meta V.! id)

findValueInFunction :: T.Text -> META -> IO EVAL
findValueInFunction iden meta = do
  values <- mapM (getEvalByIden iden) (EvalMeta.closure meta)
  let val = find isJust values
  return (fromJust (fromJust val))
     

addUpdateValueToMeta :: ID -> META -> IO META
addUpdateValueToMeta id meta = return meta{variableValues=V.update (variableValues meta) (V.singleton (id, eval meta))}

addUpdateScopeInMeta :: T.Text -> META -> IO META
addUpdateScopeInMeta iden meta = do
  clos <- updateScopeInClosure iden (eval meta) (EvalMeta.closure meta)
  return meta{EvalMeta.closure=clos}
  
addUpdateScopeInMetaWithEval :: T.Text -> EVAL -> META -> IO META
addUpdateScopeInMetaWithEval iden eval meta = do
  clos <- updateScopeInClosure iden eval (EvalMeta.closure meta)
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