{-# LANGUAGE OverloadedStrings #-}

module Runners where

import Scanner
import TokenHelper

import System.Environment
import qualified Data.Text.IO as TIO
import qualified Data.Text as T
import GHC.IO.Handle (hFlush)
import System.IO (stdout)
import qualified Data.Sequence as S
import Parser
import ParseExpressions
import Eval
import AST
import Data.Maybe
import EvalTypes
import Utils

run :: T.Text -> IO()
run text = do
  let tokens = scanTokens text
  printScanErrorOrContinue tokens

runLoxFile :: T.Text -> IO ()
runLoxFile arg = do
  text <- TIO.readFile (T.unpack arg)
  run text
  
-- TODO: Prompt should remember all variables, and run should use it
-- So a helper function which has a list of argument (all new inputs are added into that)
-- and after the scan, we scan if the tokens has the saved identifier, swap it with their values
-- parse and evaluate
runPrompt :: IO()
runPrompt = do
  input <- readFromRepl
  run (T.pack input)
  runPrompt
  

startLox :: [T.Text] -> IO ()
startLox args
  | argsLength == 1 = runLoxFile (head args)
  | argsLength > 1 = putStrLn "Use one or less args"
  | otherwise = runPrompt
  where argsLength = length args
  
startFromTerminal :: IO()
startFromTerminal = do
    args <- getArgs
    let newArgs = map T.pack args
    startLox newArgs


-- Helpers

-- This is the code I used. Thanks Joel Chelliah!
-- https://github.com/joelchelliah/simple-repl-in-haskell/blob/master/README.md
readFromRepl :: IO String
readFromRepl = putStr "Lox> "
     >> hFlush stdout
     >> getLine

printScanErrorOrContinue :: S.Seq Token -> IO ()
printScanErrorOrContinue tokens = if null scanError then printEvalOrContinue parsed else print scanError
  where scanError = S.filter (isNotToken . tokenType) tokens
        parsed = parse tokens

printEvalOrContinue :: AST.PROGRAM -> IO ()
printEvalOrContinue (PROG statements) = handleCases
  where parseError = findParseError statements S.empty
        astError = S.filter isJust (fmap getASTErrorFromStatement statements)
        handleCases
          | (not . null) parseError = print (mconcat ["ParserError: ", show parseError])
          | (not . null) astError = print (mconcat ["ParserError: ", show astError])
          | otherwise = evalProgram (PROG statements)
printEvalOrContinue parseError = print parseError