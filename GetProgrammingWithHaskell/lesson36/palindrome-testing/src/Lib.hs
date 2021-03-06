module Lib
    ( isPalindrome,
        preprocess
    ) where

import Data.Text as T
import Data.Char (isPunctuation, isSpace, toLower)

stripWhiteSpace :: T.Text -> T.Text 
stripWhiteSpace text = T.filter (not . isSpace) text

stripPunctuation :: T.Text -> T.Text 
stripPunctuation text = T.filter (not . isPunctuation) text

toLowerCase :: T.Text -> T.Text 
toLowerCase text = T.toLower text


preprocess :: T.Text -> T.Text 
preprocess = stripWhiteSpace . stripPunctuation . toLowerCase


isPalindrome :: T.Text -> Bool
isPalindrome text = cleanText == T.reverse cleanText
    where cleanText = preprocess text



