module Utils where

import qualified Data.Text as T

-- Types
type TextType = T.Text
data ID = ID Int | NON_ID deriving (Eq, Show) 