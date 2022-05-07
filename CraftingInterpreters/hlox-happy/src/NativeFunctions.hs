{-# LANGUAGE OverloadedStrings #-}


module NativeFunctions where

import System.Clock
import qualified Data.Vector as V
import EvalTypes
import NativeFunctionTypes
import AST
import Utils

-- TODO: See if there is a nicer solution (Maybe Data.Time)
-- (Integer -> Integer) function is needed that is how I could force it to not return the same number every time I call it
clock :: (Integer -> Integer) -> IO Integer
clock f = do
  valInNanoSec <- toNanoSecs <$> getTime Realtime
  return (f (div valInNanoSec 1000000))

-- This two function is called

createGlobalVector :: V.Vector EVAL
createGlobalVector = V.singleton (NATIVE_FUNC_DEC_EVAL
                               "clock"
                               0
                               []
                               (CLOCK clock))
                               
createGlobalDeclaration :: V.Vector DECLARATION
createGlobalDeclaration = V.singleton (DEC_FUNC (NATIVE_FUNC "clock" [] (ID 0)))


