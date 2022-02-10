{-# LANGUAGE OverloadedStrings #-}

module Main where

import Runners
import HappyParser as H


main :: IO ()
main = do
  print (H.happyParser "5 and 6")
  --startFromTerminal

