module Utils where

import qualified Data.Text as T

-- Types
type TextType = T.Text

-- The index of the declarationVector in Resolver, and index in the variableVector in the resolver and the eval
data ID = ID Int | NON_ID deriving (Eq, Show) 