{-# LANGUAGE OverloadedStrings #-}

module EvalMeta where

import ResolverTypes
import Resolver
import qualified Data.Vector as V
import EvalTypes
import AST
import NativeFunctions

-- META
data META = META {
  isInFunction :: Bool
  , isInLoop :: Bool
  , variableValues :: V.Vector EVAL
  , globalVariableValues :: V.Vector EVAL
                 } deriving Show


createGlobalMeta ::  V.Vector EVAL -> IO META
createGlobalMeta vector = do
  return META { isInFunction=False, isInLoop=True, variableValues=vector, globalVariableValues=createGlobalVector }

findValueInMeta :: ID -> META -> IO EVAL
findValueInMeta (LOCAL_ID id) meta = return (variableValues meta V.! id)
findValueInMeta (GLOBAL_ID id) meta = return (globalVariableValues meta V.! id)
findValueInMeta NOT_READY meta = return EVAL_NIL


addUpdateValueToMeta :: ID -> EVAL -> META -> IO META
addUpdateValueToMeta (LOCAL_ID id) eval meta = return meta{variableValues=(V.update (variableValues meta) (V.singleton (id, eval)))}
