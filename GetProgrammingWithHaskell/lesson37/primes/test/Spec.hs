import Test.QuickCheck
import Primes
import Data.Maybe

prop_validPrimesOnly val = if val < 2 || val >= 10000 then isNothing result else isJust result
    where result = isPrime val

prop_primesArePrimes val = if result == Just True then length divisors == 0 else True 
    where result = isPrime val
          divisors = filter ((== 0) . (val `mod`)) [2 .. (val - 1)]

prop_nonPrimesAreComposite val = if result == Just False then length divisors > 0 else True
    where result = isPrime val
          divisors = filter ((==0) . (val `mod`)) [2 .. (val - 1)]

prop_factorsMakeOriginal val = if isNothing result then True else product (fromJust result) == val
    where result = primeFactors val

prop_allFactorsPrime val = isNothing result || all (== Just True) resultsPrime
 where result = primeFactors val
       resultsPrime = map isPrime (fromJust result)

main :: IO ()
main = do
    quickCheck prop_validPrimesOnly
    quickCheckWith stdArgs {maxSuccess = 1000}  prop_primesArePrimes
    quickCheckWith stdArgs {maxSuccess = 1000}  prop_nonPrimesAreComposite
    quickCheck prop_factorsMakeOriginal
    quickCheck prop_allFactorsPrime
