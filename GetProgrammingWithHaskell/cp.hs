{-# LANGUAGE OverloadedStrings #-}
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import System.IO
import System.Environment


main :: IO()
main = do
    args <- getArgs 
    let from = head args
    let to = head (tail args)
    input <- TIO.readFile from
    fileTo <- TIO.writeFile to input
    TIO.putStrLn input