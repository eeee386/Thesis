{-# LANGUAGE OverloadedStrings #-}
import qualified Data.Text as T
import qualified Data.Text.IO as TIO

toInts :: T.Text -> [Int]
toInts = map (read . T.unpack) . T.lines

main :: IO()
main = do
    userInput <- TIO.getContents 
    let numbers = toInts userInput
    print (sum numbers)
