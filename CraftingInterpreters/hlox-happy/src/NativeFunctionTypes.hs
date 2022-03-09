module NativeFunctionTypes where

import qualified Data.Text as T
import qualified Data.HashTable.IO as HT
import Utils

newtype NATIVE_FUNCTION_TYPES = CLOCK ((Integer -> Integer) -> IO Integer)
instance Show NATIVE_FUNCTION_TYPES where
  show _ = "Native code"
instance Eq NATIVE_FUNCTION_TYPES where
  (==) _ _ = False
