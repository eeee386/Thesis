{-# LANGUAGE OverloadedStrings #-}

module Main where

import Runners
import HappyParser as H
import AST
import ResolverTypes
import Resolver

main :: IO ()
main = do
  meta <- resolveProgram (H.happyParser "var a = 6; {var b = 2; c = 7; var c = b + 6;} a = 8;")
  let decs = declarations meta
  print decs
  print (resolverErrors meta)
  --startFromTerminal

