import Control.Monad
import Data.Char

powersOfTwo :: Int -> [Int]
powersOfTwo n = do
    value <- [1 .. n]
    return (value^2)

-- powersOfTwo n = map (^2) [1 .. n]

powersOfTwoAndThree :: Int -> [(Int, Int)]
powersOfTwoAndThree n = do
    value <- [1 .. n]
    return (2^value, 3^value)

valAndSquare :: Int -> [(Int, Int)]
valAndSquare n = do
    value <- [1 .. n]
    return (value, value^2)

evensGuard :: Int -> [Int]
evensGuard n = do
    value <- [1 .. n]
    guard(even value)
    return value

filterGuard :: (a -> Bool) -> [a] -> [a]
filterGuard f list = do
    value <- list
    guard(f value)
    return value

evenSquares :: [Int]
evenSquares = do
    n <- [0 .. 9]
    let nsquared = n^2
    guard(even nsquared)
    return n

powersOfTwoAndThreeComp ::  Int -> [(Int, Int)]
powersOfTwoAndThreeComp n = [(powersOfTwo, powersOfThree) | value <- [1 .. n], let powersOfTwo = value^2, let powersOfThree = value^3]

allEvenOddsComp :: Int -> [(Int, Int)]
allEvenOddsComp n = [(evens, odds) | evens <- [2,4 .. n], odds <- [1,3 .. n]]

evensGuardDo ::  Int -> [Int]
evensGuardDo n = [value | value <- [1 .. n], even value]


qc3 :: [String]
qc3 =
  [ "Mr. " ++ uColor
  | color <- ["brown", "blue", "pink", "orange"]
  , let uColor = (\(x:xs) -> toUpper x:xs) color
  ] -- ["Mr. Brown","Mr. Blue","Mr. Pink","Mr. Orange"]