{-# LANGUAGE OverloadedStrings #-}

module Runners where

import Scanner

import System.Environment
import qualified Data.Text.IO as TIO
import qualified Data.Text as T
import GHC.IO.Handle (hFlush)
import System.IO (stdout)

run :: T.Text -> IO()
run text = print (scanTokens text)

-- This is the code I used. Thanks Joel Chelliah!
-- https://github.com/joelchelliah/simple-repl-in-haskell/blob/master/README.md
readFromRepl :: IO String
readFromRepl = putStr "Lox> "
     >> hFlush stdout
     >> getLine

runLoxFile :: T.Text -> IO ()
runLoxFile arg = do
  text <- TIO.readFile (T.unpack arg)
  run text
  
runPrompt :: IO()
runPrompt = do
  input <- readFromRepl
  run (T.pack input)
  runPrompt
  

readLoxFile :: [T.Text] -> IO ()
readLoxFile args
  | argsLength == 1 = runLoxFile (head args)
  | argsLength > 1 = putStrLn "Use one or less args"
  | otherwise = runPrompt
  where argsLength = length args
  
startFromTerminal :: IO()
startFromTerminal = do
    args <- getArgs
    let newArgs = map T.pack args
    readLoxFile newArgs