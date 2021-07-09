main :: IO()
-- I misinterpreted the problem, made  different solution
{-main = do
    res <- getLine
    let num = read res
    addMultForever num 

addOrmultiply :: Int -> String -> Int -> Int
addOrmultiply num1 sign num2 =  if sign == "+" then num1 + num2 else num1 * num2

addMultForever res = do
        sign <- getLine
        num <- getLine
        let num2 = read num
        let res2 = addOrmultiply res sign num2
        print res2
        addMultForever res2-}

calc :: [String] -> Int
calc (val1:"+":val2:rest) = read val1 + read val2
calc (val1:"*":val2:rest) = read val1 * read val2

main = do
    userInput <- getContents 
    let values = lines userInput
    print (calc values)