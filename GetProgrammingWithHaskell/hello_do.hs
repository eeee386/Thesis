askForName :: IO()
askForName = putStrLn "What is your name?"

nameStatement :: String -> String
nameStatement name = mconcat ["Hello, ", name, "!"]

{-main :: IO()
main = do
    askForName
    name <- getLine 
    putStrLn (nameStatement name)
-}
main :: IO()
main = do
    name <- getLine 
    let statement = nameStatement name
    putStrLn statement

main = getLine >>= (\name -> (\statement -> putStrLn statement) nameStatement name)