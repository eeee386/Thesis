data FiveSidedDice = S1 | S2 | S3 | S4 | S5 deriving (Show, Enum, Eq, Ord)

class Dice a where 
    roll ::  Int -> a

instance Dice FiveSidedDice where
    roll n = toEnum (n `mod` 5)