{-# LANGUAGE OverloadedStrings #-}

module Error where

import qualified Data.Text as T
import qualified Data.Text.IO as TIO

report :: Int -> T.Text -> T.Text -> IO()
report line whereWas message = TIO.putStrLn (mconcat ["Error on line: ", T.pack (show line), ". ", whereWas, ": ", message ])
  
error :: Int -> T.Text -> IO()
error line message = report line "" message

