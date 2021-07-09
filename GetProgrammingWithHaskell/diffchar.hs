{-# LANGUAGE OverloadedStrings #-}
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import System.IO
import System.Environment
import qualified Data.ByteString as B
import qualified Data.ByteString.Char8 as BC

main :: IO()
main = do
    args <- getArgs
    let fileName = head args
    input <- TIO.readFile fileName
    let len = T.length input
    bytes <- BC.readFile fileName
    let bytelen = BC.length bytes
    print (bytelen - len)
