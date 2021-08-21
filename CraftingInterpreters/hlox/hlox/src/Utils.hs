module Utils where

import qualified Data.Sequence as S
import TokenHelper

getLast :: S.Seq a -> Maybe a
getLast s = S.lookup (S.length s -1) s

findElement :: (a -> Bool) -> S.Seq a -> Maybe a
findElement pr s = S.index s <$> index
  where index = S.findIndexL pr s 
  
tokenIsType :: TokenType -> Token -> Bool
tokenIsType tType token = tokenType token == tType