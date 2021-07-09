import System.Environment
import Control.Monad

main :: IO()
main = do
    args <- getArgs 
    mapM_ putStrLn args
    let linesToRead = if length args > 0 then read (head args) else 0 :: Int
    numbers <- replicateM linesToRead getLine
    let ints = map read numbers::[Int]
    print (sum ints)

-- Quick check 22.1
{-main :: IO()
main = do
    vals <- mapM (\_ -> getLine) [1 .. 3]
    mapM_ putStrLn [arg1, arg2, arg3]-}

myReplicateM n action = mapM (\_ -> action) [1 .. n] 