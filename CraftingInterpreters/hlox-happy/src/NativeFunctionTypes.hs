module NativeFunctionTypes where

newtype NATIVE_FUNCTION_TYPES = CLOCK ((Integer -> Integer) -> IO Integer)
instance Show NATIVE_FUNCTION_TYPES where
  show _ = "Native code"
instance Eq NATIVE_FUNCTION_TYPES where
  (==) _ _ = False
