import qualified Data.Map as Map


successfulRequest :: Maybe Int
successfulRequest = Just 6

failedRequest :: Maybe Int
failedRequest = Nothing

reverseMaybeString :: Maybe String -> Maybe String
reverseMaybeString str = fmap reverse str

data RobotPart = RobotPart {
    name :: String,
    description :: String,
    cost :: Double,
    count :: Int
} deriving Show


leftArm :: RobotPart
leftArm = RobotPart
  { name        = "left arm"
  , description = "left arm for face punching!"
  , cost        = 1000.00
  , count       = 3
  }

rightArm :: RobotPart
rightArm = RobotPart
  { name        = "right arm"
  , description = "right arm for kind hand gestures"
  , cost        = 1025.00
  , count       = 5
  }

robotHead :: RobotPart
robotHead = RobotPart
  { name        = "robot head"
  , description = "this head looks mad"
  , cost        = 5092.25
  , count       = 2
  }



type Html = String
renderHtml :: RobotPart -> Html
renderHtml part = mconcat [
    "<h2>", partName, "</h2>", "<p><h3>desc</h3>", partDesc,"</p>", "<p><h3>cost</h3>", partCost, "</p>", "<p><h3>count</h3>", partCount, "</p>"]
    where partName = name part
          partDesc = description part
          partCost = show (cost part)
          partCount = show (count part)


partsDB :: Map.Map Int RobotPart
partsDB = Map.fromList keyVals
    where keys = [1,2,3]
          values = [leftArm, rightArm, robotHead]
          keyVals = zip keys values

partVal :: Maybe RobotPart
partVal = Map.lookup 1 partsDB

partHtml :: Maybe Html
partHtml = renderHtml <$> partVal

allParts :: [RobotPart]
allParts = map snd (Map.toList partsDB)

allPartsHtml :: [Html]
allPartsHtml = map renderHtml allParts

htmlPartsDB :: Map.Map Int Html
htmlPartsDB = renderHtml <$> partsDB

leftArmIO :: IO RobotPart
leftArmIO = return leftArm

htmlSnippet :: IO Html
htmlSnippet = renderHtml <$> leftArmIO

data Box a = Box a deriving Show

instance Functor Box where
    fmap func (Box a) = Box (func a)

morePresents :: Int -> Box a -> Box [a]
morePresents n a = fmap (replicate n) a

myBox :: Box Int 
myBox = Box 1

otherBox :: Box Int
otherBox = fmap id myBox


wrapped :: Box (Box Int)
wrapped  = fmap (\x -> Box x) myBox

unwrap :: Box a -> a
unwrap (Box a) = a

printCost :: Maybe Double -> IO()
printCost Nothing = putStrLn "item not found"
printCost (Just cost) = print cost

main = do
    idStr <- getContents
    let idv = read idStr 
    printCost (fmap cost (Map.lookup idv partsDB))
    