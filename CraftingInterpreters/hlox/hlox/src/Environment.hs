module Environment where

import qualified Data.HashTable.IO as HT
import qualified Control.Monad.ST as ST

import Eval
import AST

values :: IO (HT.BasicHashTable AST.TextType EVAL)
values = HT.new

addUpdateIdentifier :: PROG_EVAL -> IO()
addUpdateIdentifier (DEC_EVAL iden value) = do
   val <- values
   HT.insert val iden value 
addIdentifier _ = return ()

getValueOfIdentifier :: TextType -> IO(Maybe EVAL)
getValueOfIdentifier iden = do
  val <- values
  HT.lookup val iden
   


