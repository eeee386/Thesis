{-# LANGUAGE OverloadedStrings #-}

module Environment where

import qualified Data.HashTable.IO as HT

import EvalTypes
import AST

values :: IO (HT.BasicHashTable AST.TextType EVAL)
values = HT.new

addUpdateIdentifier :: AST.TextType -> EVAL -> IO()
addUpdateIdentifier iden value = do
   val <- values
   print "insert happens"
   HT.insert val iden value
   gett <- HT.lookup val iden
   print gett

getValueOfIdentifier :: AST.TextType -> IO (Maybe EVAL)
getValueOfIdentifier iden = do
  val <- values
  print "this is called"
  gett <- HT.lookup val iden
  print gett
  HT.lookup val iden



