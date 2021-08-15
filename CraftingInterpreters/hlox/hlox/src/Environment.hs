module Environment where

import qualified Data.HashTable.IO as HT
import qualified Control.Monad.ST as ST

import Eval
import AST

values :: IO (HT.BasicHashTable AST.TextType EVAL)
values = HT.new

addIdentifier :: PROG_EVAL -> IO()
addIdentifier (DEC_EVAL iden value) = do
   val <- values
   HT.insert val iden value 
addIdentifier _ = return ()
   


