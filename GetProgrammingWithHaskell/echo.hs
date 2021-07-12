echo :: IO()
echo = getLine >>= putStrLn

{-
echoDo = do
    str <- getLine
    purStrLn str
-}

