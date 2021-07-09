{-# LANGUAGE OverloadedStrings #-}
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import System.IO
import System.Environment
import Data.Char


main :: IO()
main = do
    args <- getArgs 
    let fileName = head args
    input <- TIO.readFile fileName
    TIO.writeFile fileName (T.toUpper input)

