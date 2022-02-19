{-# LANGUAGE OverloadedStrings #-}

module Main where

import Runners
import HappyParser as H
import AST
import ResolverTypes
import Resolver

main :: IO ()
main = do
  meta <- resolveProgram (H.happyParser "var a = 0;fun b(){print a;}")
  let decs = declarations meta
  print decs
  print (resolverErrors meta)
  --startFromTerminal

