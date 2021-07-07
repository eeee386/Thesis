calcChange :: (Ord p, Num p) => p -> p -> p
calcChange owed given = if change > 0 then change else 0
                        where change = given - owed


doublePlusTwo :: Num a => a -> a
doublePlusTwo x = doubleX + 2
                    where doubleX = 2*x

inc :: Num a => a -> a
inc x = x + 1
square x = x*x
double x = x*2



func :: Integral a => a -> a
func n = if even n then n-2 else 3*n-1

sumSquareOrSquareSum x y = (\sumSquare squareSum -> if sumSquare > squareSum then sumSquare else squareSum) (x^2 + y^2) (x+y)^2

doubledoubleX x = (\dubs -> 2*dubs) (x*2)

sumSquareOrSquareSum' x y = let sumSquare = (x^2 + y^2)
                                squareSum = (x+y)^2
                            in
                                if sumSquare > squareSum then sumSquare else squareSum

overwriteLambda = (\x -> (\x -> (\x -> x) 4 ) 3 ) 2

libraryAdd x y = (\x y -> x+y) x y

ifEvenDo :: (Int -> Int) -> Int -> Int
ifEvenDo f x = if even x then f x else x

names = [("Ian", "Curtis"), ("Will", "Smith")]

compareNames f get name1 name2 
    | gname1 > gname2 = GT 
    | gname1 < gname2 = LT 
    | otherwise = f
    where 
        gname1 = get name1
        gname2 = get name2

compareNames' f get name1 name2 =
    if res == GT || res == LT then res else f
    where res = compare gname1 gname2
          gname1 = get name1
          gname2 = get name2

eq = EQ

compareFirstNames name1 name2 = compareNames eq fst name1 name2

compareLastNames name1 name2 = compareNames (compareFirstNames name1 name2) snd name1 name2

