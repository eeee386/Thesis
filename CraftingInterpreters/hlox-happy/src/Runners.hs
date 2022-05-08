{-# LANGUAGE OverloadedStrings #-}

module Runners where


import System.Environment
import qualified Data.Text.IO as TIO
import qualified Data.Text as T
import GHC.IO.Handle (hFlush)
import System.IO (stdout)
import Eval
import ResolverTypes
import Resolver
import qualified Generated.HappyParser as H


-- TODO: Use string here or use text in the lexer
run :: T.Text -> IO()
run text = do
  let ast = H.happyParser (T.unpack text)
  resolverMeta <- resolveProgram ast
  if not (null (resolverErrors resolverMeta)) then do
    mapM_ print (resolverErrors resolverMeta)
  else do
    evalProgram (declarations resolverMeta) (variableVector resolverMeta)
    return ()

runLoxFile :: T.Text -> IO ()
runLoxFile arg = do
  text <- TIO.readFile (T.unpack arg)
  run text

-- TODO: Prompt should remember all variables, and run should use it
-- So a helper function which has a list of arguments (all new inputs are added into that)
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
