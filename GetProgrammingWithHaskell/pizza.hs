import Data.Map as Map

areaGivenDiameter :: Double -> Double 
areaGivenDiameter size = pi*(size/2)^2

type Pizza = (Double, Double)

costPerInch :: Pizza -> Double 
costPerInch (size, cost) = cost / areaGivenDiameter size

comparePizzas :: Pizza -> Pizza -> Pizza
comparePizzas p1 p2 = if costPerInch p1 < costPerInch p2 then p1 else p2

describePizza :: Pizza -> String 
describePizza (size, cost) = mconcat ["The ", show size, " pizza is cheaper at ", show cstPerInch, " per square inch"]
    where cstPerInch = costPerInch (size, cost)

main :: IO ()
main = do
  putStr "What is the size of pizza 1? "
  size1 <- getLine
  putStr "What is the cost of pizza 1? "
  cost1 <- getLine
  putStr "What is the size of pizza 2? "
  size2 <- getLine
  putStr "What is the cost of pizza 2? "
  cost2 <- getLine
  let pizza1      = (read size1, read cost1)
  let pizza2      = (read size2, read cost2)
  let betterPizza = comparePizzas pizza1 pizza2
  putStrLn (describePizza betterPizza)

costData :: Map.Map Int Double
costData = Map.fromList [(1, 18.0), (2, 16.0)]

sizeData :: Map.Map Int Double
sizeData = Map.fromList [(1, 20.0), (2, 15.0)]

maybeMain :: Maybe String
maybeMain = do
  size1 <- Map.lookup 1 sizeData
  cost1 <- Map.lookup 1 costData
  size2 <- Map.lookup 2 sizeData
  cost2 <- Map.lookup 2 costData
  let pizza1      = (size1, cost1)
  let pizza2      = (size2, cost2)
  let betterPizza = comparePizzas pizza1 pizza2
  return (describePizza betterPizza)
 
 