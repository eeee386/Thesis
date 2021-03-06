module Utils where

import qualified Data.Sequence as S
import TokenHelper
import Data.Maybe
import qualified Data.Text as T

-- Types
type TextType = T.Text
data ID = LOCAL_ID Int | GLOBAL_ID Int | NOT_READY | PARAM | METHOD deriving (Eq, Show)

-- Helper Functions
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
        
        
findMatchingBraceIndex ::  S.Seq Token -> Maybe Int
findMatchingBraceIndex = findMatching LEFT_BRACE RIGHT_BRACE 0 0


-- Stack
type Stack = []

createStack :: Stack a
createStack = []

pop :: Stack a -> (a, Stack a)
pop (x:xs) = (x,xs)

push :: a -> Stack a -> Stack a
push x xs = x:xs

peek :: Stack a -> a
peek = head
