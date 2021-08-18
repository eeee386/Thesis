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
import Eval
import AST
import Environment
import Control.Monad
import Data.Maybe


printScanErrorOrContinue :: S.Seq Token -> IO ()
printScanErrorOrContinue tokens = if null scanError then printEvalOrContinue parsed else print scanError
  where scanError = S.filter (isNotToken . tokenType) tokens
        parsed = parse tokens

printEvalOrContinue :: AST.PROGRAM -> IO ()
printEvalOrContinue (PROG statements eof) = handleCases
  where parseError = S.filter isJust (fmap getParseError statements)
        astError = S.filter isJust (fmap getASTErrorFromStatement statements)
        evaled = evalProgram (PROG statements eof) 
        handleCases 
          | (not . null) parseError = print (mconcat ["ParserError: ", show parseError])
          | (not . null) astError = print (mconcat ["ParserError: ", show astError])
          | otherwise = runByLines evaled
printEvalOrContinue parseError = print parseError

runByLines :: S.Seq PROG_EVAL -> IO()
runByLines = mapM_ runOneLine
  
-- Run one lines should be called -> save identifiers from it (Maybe not necessary, will leave it as return, and we will see what happens)
runOneLine :: PROG_EVAL -> IO()
runOneLine (PRINT_EVAL x) = print x
runOneLine (EXPR_EVAL x) = return ()
runOneLine y = addUpdateIdentifier y

       
  
run :: T.Text -> IO()
run text = do
  let tokens = scanTokens text
  print (handleCreateDeclaration tokens)
  printScanErrorOrContinue tokens

-- This is the code I used. Thanks Joel Chelliah!
-- https://github.com/joelchelliah/simple-repl-in-haskell/blob/master/README.md
readFromRepl :: IO String
readFromRepl = putStr "Lox> "
     >> hFlush stdout
     >> getLine

-- TODO: We will have to deal with variables and block scopes, good luck future me.
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