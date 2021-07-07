data FourLetterAlphabet = L1 | L2 | L3 | L4 deriving (Show, Enum, Bounded)
data ThreeLetterAlphabet = Alpha | Beta | Kappa deriving (Show, Enum, Bounded)

rotN :: (Bounded a, Enum a) => Int -> a -> a
rotN alphabetSize c = toEnum rotation
    where halfAlphabet = alphabetSize `div` 2
          offset = fromEnum c + halfAlphabet
          rotation = offset `mod` alphabetSize

-- Enum indexes from 0
largestCharNumber :: Int 
largestCharNumber = fromEnum (maxBound :: Char)

rotChar :: Char -> Char 
rotChar charToEncrypt = rotN sizeOfAlphabet charToEncrypt
    where sizeOfAlphabet = 1 + fromEnum (maxBound :: Char)


message :: [FourLetterAlphabet]
message = [L1, L3, L4, L1, L1, L2]

fourLetterAlphabetEncoder :: [FourLetterAlphabet] -> [FourLetterAlphabet]
fourLetterAlphabetEncoder message = map rot4 message
    where rot4 = rotN (1 + fromEnum (maxBound :: FourLetterAlphabet))


rotNdecoder :: (Bounded a, Enum a) => Int -> a -> a
rotNdecoder n c = toEnum rotation
    where halfN = n `div` 2
          offset = if even n then fromEnum c + halfN else 1 + fromEnum c + halfN
          rotation = offset `mod` n


rotEncoder :: String -> String
rotEncoder text = map rotChar text
    where alphaSize = 1 + fromEnum (maxBound :: Char)
          rotChar = rotN alphaSize

rotDecoder :: String -> String 
rotDecoder text = map rotCharDecoder text
    where rotCharDecoder = rotNdecoder (1+fromEnum (maxBound :: Char))

threeLetterEncoder :: [ThreeLetterAlphabet] -> [ThreeLetterAlphabet]
threeLetterEncoder text = map rot3 text
    where rot3 = rotN (1+ fromEnum (maxBound :: ThreeLetterAlphabet))


threeLetterDecoder :: [ThreeLetterAlphabet] -> [ThreeLetterAlphabet]
threeLetterDecoder text = map rot3Dec text
    where rot3Dec = rotNdecoder (1+fromEnum (maxBound :: ThreeLetterAlphabet))


fourLetterEncoder :: [FourLetterAlphabet] -> [FourLetterAlphabet]
fourLetterEncoder text = map rot3 text
    where rot3 = rotN (1+ fromEnum (maxBound :: FourLetterAlphabet))


fourLetterDecoder :: [FourLetterAlphabet] -> [FourLetterAlphabet]
fourLetterDecoder text = map rot4Dec text
    where rot4Dec = rotNdecoder (1+fromEnum (maxBound :: FourLetterAlphabet))

class Cypher a where
    encode :: a -> String -> String 
    decode :: a -> String -> String 

data Rot = Rot

instance Cypher Rot where
    encode Rot text = rotEncoder text
    decode Rot text = rotDecoder text


          