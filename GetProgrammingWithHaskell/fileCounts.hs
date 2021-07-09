{-# LANGUAGE OverloadedStrings #-}
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import System.IO
import System.Environment

getCounts :: T.Text -> (Int, Int, Int)
getCounts input = (T.length input, length (T.words input), length (T.lines input))

countsText :: (Show a1, Show a2, Show a3) => (a1, a2, a3) -> T.Text
countsText (cc, wc, lc) = T.pack (unwords ["chars: ",show cc, " words: ", show wc, " lines: ", show lc])

main :: IO()
main = do
    args <- getArgs
    let fileName = head args
    input <- TIO.readFile fileName
    let summary = (countsText . getCounts) input
    TIO.appendFile "stats.dat" (mconcat [T.pack fileName, " ", summary, "\n"])
    TIO.putStrLn summary

