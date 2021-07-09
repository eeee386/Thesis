import System.Random

minDice :: Int 
minDice = 1

maxDice :: Int 
maxDice = 6

main :: IO()
main = do
    dieRoll <- randomRIO (minDice, maxDice)
    putStrLn (show dieRoll)
 