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

findMatching ::TokenType -> TokenType -> Int -> Int -> S.Seq Token -> Maybe Int
findMatching left right surplus index tokens 
  | tType == Just left = findMatching left right (surplus+1) (index+1)  tTail 
  | tType == Just right = if surplus-1 == 0 then Just index else findMatching left right (surplus-1) (index+1) tTail 
  | S.null tokens = Nothing
  | otherwise = findMatching left right surplus (index+1) tTail 
  where tTail = S.drop 1 tokens
        tType = tokenType <$> S.lookup 0 tokens
        

-- Find matching brace
findMatchingBraceIndex ::  S.Seq Token -> Maybe Int
findMatchingBraceIndex = findMatching LEFT_BRACE RIGHT_BRACE 0 0


-- Stack
type Stack = []

createStack :: Stack a
createStack = []

popStack :: Stack a -> (a, Stack a)
popStack (x:xs) = (x,xs)

pushStack :: Stack a -> a -> Stack a
pushStack stack x = x:stack

peekStack :: Stack a -> a
peekStack (x:xs) = x
