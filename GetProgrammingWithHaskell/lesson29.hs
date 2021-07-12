primesToN :: Int -> [Int]
primesToN n = filter isNotComposite twoThroughN
    where twoThroughN = [2 .. n]
          composite = pure (*) <*> twoThroughN <*> twoThroughN
          isNotComposite = not . (`elem` composite)

allFmap :: Applicative f => (a -> b) -> f a -> f b
allFmap f a = pure (f) <*> a 

example :: Maybe Int 
example = pure (*) <*> (pure (+) <*> 2 <*> pure 4) <*> 6 

beers = pure (*) <*> (pure (*) <*> (pure (-) <*> [6,12] <*> pure (-2)) <*> [2,3]) <*> [3,4]