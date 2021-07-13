module Main where
import qualified Data.ByteString.Char8 as BC
import System.Environment
import Glitch


main :: IO()
main = do
    args <- getArgs
    let fileName = head args
    imageFile <- BC.readFile fileName
    let glitched = foldM (\bytes func -> func bytes) imageFile [randomReplaceBytes, randomSortSection, randomReplaceBytes, randomSortSection, randomReplaceBytes]
    let glitchedFileName = mconcat ["glitched_", fileName]
    BC.writeFile glitchedFileName glitched
    print "all done"