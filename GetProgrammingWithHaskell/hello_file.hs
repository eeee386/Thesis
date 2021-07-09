import System.IO

main :: IO()
{-main = do
    myFile <- openFile "hello.txt" ReadMode
    firstLine <- hGetLine myFile
    putStrLn firstLine
    secondLine <- hGetLine myFile
    goodbyeFile <- openFile "goodbye.txt" WriteMode 
    hPutStrLn goodbyeFile secondLine 
    hClose myFile
    hClose goodbyeFile
    putStrLn "done!" 
-}

main = do
    helloFile <- openFile "hello.txt" ReadMode
    firstLine <- hGetLine helloFile
    hasSecondLine <- hIsEOF helloFile
    hClose helloFile
    if not hasSecondLine then putStrLn "failed" else do
        helloFile <- openFile "hello.txt" WriteMode 
        hPutStrLn helloFile "Written"
        putStrLn "done"

{-main = do
    helloFile <- openFile "hello.txt" ReadMode 
    hasLine <- hIsEOF helloFile
    firstLine <- if not hasLine then hGetLine helloFile else return "empty"
    putStrLn "done"
-}
