import Data.Char

eitherHead :: [a] -> Either String a
eitherHead [] = Left "List is empty"
eitherHead (x:xs) = Right x

main :: IO()
main = return ()

allDigits :: String -> Bool
allDigits = all isDigit

addStrInts :: String -> String -> Either String Int
addStrInts a b | not (allDigits a) = Left "First value is invalid"
               | not (allDigits b) = Left "Second value is Invalid"
               | otherwise = Right (read a + read b)

safeSucc :: (Enum a, Bounded a, Eq a) => a -> Maybe a
safeSucc a = if a == maxBound then Nothing else Just (succ a)

myTail :: [a] -> [a]
myTail [] = []
myTail (x:xs) = xs

myLast :: [a] -> Either String a
myLast [] = Left "Empty list"
myLast list = if length list > 100000 then Left "List too long" else Right (head (reverse list))