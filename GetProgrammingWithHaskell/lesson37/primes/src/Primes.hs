module Primes where

maxVal :: Int
maxVal = 10000

primes :: [Int]
primes = sieve [1 .. maxVal]

sieve :: [Int] -> [Int]
sieve []                 = []
sieve (nextPrime : rest) = nextPrime : sieve noFactors
  where noFactors = filter ((/= 0) . (`mod` nextPrime)) rest

isPrime :: Int -> Maybe Bool
isPrime n | n < 2              = Nothing
          | n >= maxVal = Nothing
          | otherwise          = Just (n `elem` primes)


unsafePrimeFactors :: Int -> [Int] -> [Int]
unsafePrimeFactors 0 []              = []
unsafePrimeFactors n []              = []
unsafePrimeFactors n (next : primes) = if n `mod` next == 0
  then next : unsafePrimeFactors (n `div` next) (next : primes)
  else unsafePrimeFactors n primes

primeFactors :: Int -> Maybe [Int]
primeFactors n | n < 2              = Nothing
               | n >= maxVal = Nothing
               | otherwise          = Just (unsafePrimeFactors n primesLessThanN)
  where primesLessThanN = filter (<= n) primes
