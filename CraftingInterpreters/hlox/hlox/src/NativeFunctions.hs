module NativeFunctions where

import System.Clock
import GHC.IO.Handle (hFlush)
import System.IO (stdout)

newtype NATIVE_FUNCTION_TYPES = CLOCK ((Integer -> Integer) -> IO Integer)
instance Show NATIVE_FUNCTION_TYPES where
  show _ = "Native code"
instance Eq NATIVE_FUNCTION_TYPES where
  (==) _ _ = False

-- (Integer -> Integer) function is needed that is how I could force it to not return the same number every time I call it
clock :: (Integer -> Integer) -> IO Integer
clock f = do
  valInNanoSec <- toNanoSecs <$> getTime Realtime
  return (f (div valInNanoSec 1000000))

