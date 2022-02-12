{-# LANGUAGE OverloadedStrings #-}

module Main where

import Runners
import HappyParser as H
import AST


main :: IO ()
main = do
  let (PROG decs) = H.happyParser "5 and 6; 3+2; var a = 6;"
  print decs
  --startFromTerminal

