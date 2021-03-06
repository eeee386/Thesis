module Main where

import Pizza

main :: IO ()
main = do
  putStr "What is the size of pizza 1? "
  size1 <- getLine
  putStr "What is the cost of pizza 1? "
  cost1 <- getLine
  putStr "What is the size of pizza 2? "
  size2 <- getLine
  putStr "What is the cost of pizza 2? "
  cost2 <- getLine
  let pizza1      = (read size1, read cost1)
  let pizza2      = (read size2, read cost2)
  let betterPizza = comparePizzas pizza1 pizza2
  putStrLn (describePizza betterPizza)
