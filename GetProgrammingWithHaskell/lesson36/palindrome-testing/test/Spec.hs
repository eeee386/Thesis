import Test.QuickCheck
import Test.QuickCheck.Instances
import Lib
import Data.Char
import Data.Text as T

prop_punctuationInvariant text = preprocess text == preprocess noPuncText
    where noPuncText = T.filter (not . isPunctuation) text

prop_whitespaceInvariant text = preprocess text == preprocess noWhitespaceText
    where noWhitespaceText = T.filter (not . isSpace) text

prop_lowercaseInvariant text = preprocess text == preprocess lowercaseText
    where lowercaseText = T.toLower text

prop_InverseInvariant text = isPalindrome text == isPalindrome (T.reverse text)


main = do
    quickCheckWith stdArgs {maxSuccess=1000} prop_punctuationInvariant
    quickCheck prop_InverseInvariant
    quickCheck prop_whitespaceInvariant


