module Lib
    ( someFunc
    ) where

import qualified Data.Text.IO as TIO
import qualified Data.Text as T

someFunc :: IO ()
someFunc = do
  putStrLn "Hello World!"
