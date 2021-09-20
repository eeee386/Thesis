{-# LANGUAGE OverloadedStrings #-}


module NativeFunctions where

import System.Clock
import GHC.IO.Handle (hFlush)
import System.IO (stdout)
import qualified Data.Vector as V
import qualified Data.Text as T
import EvalTypes
import NativeFunctionTypes
import qualified Data.HashTable.IO as HT
import qualified Data.Sequence as S
import AST

-- (Integer -> Integer) function is needed that is how I could force it to not return the same number every time I call it
clock :: (Integer -> Integer) -> IO Integer
clock f = do
  valInNanoSec <- toNanoSecs <$> getTime Realtime
  return (f (div valInNanoSec 1000000))

createGlobalVector :: V.Vector EVAL
createGlobalVector = V.singleton (FUNC_DEC_EVAL
                               "clock"
                               0
                               (PARAMETERS S.empty S.empty)
                               (NATIVE_FUNC_STMT (CLOCK clock)))


createGlobalResolverTable :: IO GlobalResolverTable
createGlobalResolverTable = do
  table <- HT.new
  HT.insert table "clock" 0
  return table

getGlobalVarId ::  GlobalResolverTable -> T.Text -> IO (Maybe Int)
getGlobalVarId = HT.lookup

