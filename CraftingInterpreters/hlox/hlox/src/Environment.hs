{-# LANGUAGE OverloadedStrings #-}

module Environment where

import qualified Data.HashTable.IO as HT

import EvalTypes
import AST

type HashTable = HT.BasicHashTable AST.TextType EVAL


createEnv :: IO HashTable
createEnv = HT.new

addUpdateIdentifier :: AST.TextType -> EVAL -> HashTable -> IO HashTable
addUpdateIdentifier iden value vals = do
   HT.insert vals iden value
   return vals

getValueOfIdentifier :: AST.TextType -> HashTable -> IO (Maybe EVAL)
getValueOfIdentifier iden vals = do
  HT.lookup vals iden



