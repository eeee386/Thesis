xorBool :: Bool -> Bool -> Bool
xorBool b1 b2 = b1 /= b2

xorPair :: (Bool, Bool) -> Bool
xorPair (b1,b2) = xorBool b1 b2

xor :: [Bool] -> [Bool] -> [Bool]
xor list1 list2 = map xorPair (zip list1 list2)

type Bits = [Bool]

intToBits' :: Int -> Bits
intToBits' 0 = [False]
intToBits' 1 = [True]
intToBits' n = if remainder == 0 then False : intToBits' nextVal else True : intToBits' nextVal
    where remainder = n `mod` 2
          nextVal = n `div` 2

maxBits :: Int
maxBits = length (intToBits' maxBound)

intToBits :: Int -> Bits
intToBits n = leadingFalses ++ reversedBits
    where reversedBits = reverse (intToBits' n)
          missingBits = maxBits - length reversedBits
          leadingFalses = replicate missingBits False

charToBits :: Char -> Bits
charToBits char = intToBits (fromEnum char)

bitsToInt :: Bits -> Int
bitsToInt bits = sum (map (\x -> 2^(snd x)) trueLocations)
    where size = length bits
          indices = [size-1, size-2 .. 0]
          trueLocations = filter (\x -> fst x) (zip bits indices)

bitsToChar :: Bits -> Char 
bitsToChar bits = toEnum (bitsToInt bits)


myPad :: String 
myPad = "Shhhhhh"

myPlainText :: String 
myPlainText = "Haskell"


applyOneTimePadBits :: String -> String -> [Bits]
applyOneTimePadBits pad plainText = map (\pair -> (fst pair) `xor` (snd pair)) (zip padBits plainTextBits)
    where padBits = map charToBits pad
          plainTextBits = map charToBits plainText 

applyOneTimePad :: String -> String -> String 
applyOneTimePad pad plainText = map bitsToChar bitList
    where bitList = applyOneTimePadBits pad plainText

encoderDecoder :: String -> String
encoderDecoder = applyOneTimePad myPad

data OneTimePad = OTP String

class Cypher a where
    encode :: a -> String -> String 
    decode :: a -> String -> String 

instance Cypher OneTimePad where 
    encode (OTP pad) text = applyOneTimePad pad text
    decode (OTP pad) text = applyOneTimePad pad text

prng :: Int -> Int -> Int -> Int -> Int
prng a b maxNumber seed = (a*seed+b) `mod` maxNumber