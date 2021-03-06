{-# LANGUAGE OverloadedStrings #-}

module Main where

import qualified Data.Text.IO as TIO
import qualified Data.Text as T

import Palindrome

main :: IO()
main = do
    print "Enter a word and I'll let you know if it's a palindrome"
    text <- TIO.getLine 
    let response = if isPalindrome text then "it is" else "it's not"
    putStrLn response