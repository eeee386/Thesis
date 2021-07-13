module Main where

import Primes

getResponse :: Maybe Bool -> IO()
getResponse (Just True) = putStrLn "It is."
getResponse (Just False) = putStrLn "It is not."
getResponse Nothing = putStrLn "Cannot check"
main :: IO ()
main = do
    putStrLn "Enter number"
    value <- getLine
    let arg = read value
    getResponse (isPrime arg)
