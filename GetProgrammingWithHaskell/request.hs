getRequestUrl host apiKey resource id =
    host ++ "/" ++ resource ++ "/" ++ id ++ "?token=" ++ apiKey

genHostRequestBuilder host = getRequestUrl host

exampleUrlBuilder = genHostRequestBuilder "https://example.com"

genApiRequestBuilder hostBuilder = hostBuilder

myFunc id = getRequestUrl "https://example.com" "l337" "res"

flipBinaryArgs binf = (\x y -> binf y x)


subtract2 = flip (-) 2

assignToGroups n aList = zip groups aList
    where groups = cycle [1..n]


repeat' n = cycle [n]

subseq start end list = drop start (take end list)

gcd' a b = if remainder == 0 then b else gcd' b remainder
            where remainder = a `mod` b

myHead [] = error "empty list"
myHead (x:xs) = x

myTail [] = []
myTail (x:xs) = xs

mygcd a b
    | remainder == 0 = b
    | otherwise = mygcd b remainder
    where remainder = a `mod` b


myDrop _ [] = []
myDrop 0 list = list
myDrop n (_:xs) = myDrop (n-1) xs

myLength [] = 0
myLength (_:xs) = 1 + myLength xs

myTake 0 list = list
myTake _ [] = []
myTake n (x:xs) = x:rest
    where rest = myTake (n-1) rest


myCycle [] = []
myCycle (first:rest) = first:myCycle (rest ++ [first])

ackermann 0 n = n+1
ackermann m 0 = ackermann (m-1) 1
ackermann m n = ackermann (m-1) (ackermann m (n-1))

collatz 1 = 1
collatz n = if even n then 1 + collatz (n/2) else collatz (3*n+1)

myReverse [] = []
myReverse (x:xs) = myReverse xs ++ [x]


addAnA str = 'a':str

addanAToAll [] = []
addanAToAll (x:xs) = ('a':x):addanAToAll xs

myMap f [] = []
myMap f (x:xs) = (f x) : myMap f xs


myFilter pred [] = []
myFilter pred (x:xs) = if pred x then x:myFilter pred xs else myFilter pred xs

myRemove pred [] = []
myRemove pred (x:xs) = if pred x then myRemove pred xs else x:myRemove pred xs

myProduct list = foldl (*) 1 list


rcons x y = y:x
rev list = foldl rcons [] list

myFoldl _ init [] = init
myFoldl f s (x:xs) = myFoldl f (f s x) xs

myFoldr f init [] = init
myFoldr f init (x:xs) = f x rightValue
    where rightValue = myFoldr f x xs

myElem e list = length (filter (== e) list) > 0

--isPalindromeLetters str = map toUpper (filter (/= ' ') str)
sumOfSeries 1 = 1
sumOfSeries n = 1/n + sumOfSeries (n-1)