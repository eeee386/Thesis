{-# LANGUAGE OverloadedStrings #-}

module Main where

import Runners
import HappyParser as H
import AST


main :: IO ()
main = do
  let (PROG decs) = H.happyParser "6+a;"
  print decs
  --startFromTerminal

