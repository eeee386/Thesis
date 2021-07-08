import qualified Data.Map as Map
import Data.List

data Box a = Box a deriving Show

wrap :: a -> Box a
wrap a = Box a

unwrap :: Box a -> a
unwrap (Box a) = a

boxMap :: (a -> b) -> Box a -> Box b
boxMap f (Box x) = Box (f x)

data Triple a = Triple a a a deriving Show

first :: Triple a -> a
first (Triple x _ _) = x

second :: Triple a -> a
second (Triple _ x _) = x

third :: Triple a -> a
third (Triple _ _ x) = x

toList :: Triple a -> [a]
toList (Triple x y z) = [x,y,z]

transform :: (a -> a) -> Triple a -> Triple a
transform f (Triple x y z) = Triple (f x) (f y) (f z)

tripleMap :: (a -> b) -> Triple a -> Triple b
tripleMap f (Triple x y z) = Triple (f x) (f y) (f z)

type Point3D = Triple Double
aPoint :: Point3D
aPoint = Triple 0.1 53.2 12.3

type FullName = Triple String
aPerson :: FullName
aPerson = Triple "Howard" "Phillips" "Lovecraft"

type Initials = Triple Char
initials :: Initials
initials = Triple 'H' 'P' 'L'

data List a = Empty | Cons a (List a) deriving Show

ourMap :: (a -> b) -> List a -> List b
ourMap f Empty = Empty
ourMap f (Cons a rest) = Cons (f a) (ourMap f rest)


data Organ = Heart | Brain | Kidney | Spleen deriving (Show, Eq, Enum, Ord)

organs :: [Organ]
organs = [Heart, Heart, Brain, Spleen, Spleen, Kidney]


ids :: [Int]
ids = [2,7,13,14,21,24]

organPairs :: [(Int, Organ)]
organPairs = zip ids organs

organCatalog :: Map.Map Int Organ
organCatalog = Map.fromList organPairs

countInMap :: Eq a => [a] -> a -> Int
countInMap list organ = length (filter (\x -> x == organ) list)

countOrgans' :: Map.Map Int Organ -> [Int]
countOrgans' m = map (countInMap list) [Heart .. Spleen]
    where list = map snd (Map.toList m)

organInventory :: Map.Map Organ Int
organInventory = Map.fromList (zip [Heart .. Spleen] (countOrgans' organCatalog))

possibleDrawers :: [Int]
possibleDrawers = [1 .. 50]

getDrawerContents :: [Int] -> Map.Map Int Organ -> [Maybe Organ]
getDrawerContents ids catalog = map getContents ids
    where getContents = \id -> Map.lookup id catalog

availableOrgans :: [Maybe Organ]
availableOrgans = getDrawerContents possibleDrawers organCatalog

countOrgans :: Organ -> [Maybe Organ] -> Int
countOrgans organ available = length (filter (\x -> x == Just organ) available)

-- isJust is available
isSomething :: Maybe Organ  -> Bool
isSomething Nothing = False
isSomething (Just _) = True

justTheOrgans :: [Maybe Organ]
justTheOrgans = filter isSomething availableOrgans

showOrgan :: Maybe Organ -> String
showOrgan (Just organ) = show organ
showOrgan Nothing = ""

organList :: [String]
organList = map showOrgan justTheOrgans

cleanList :: String
cleanList = intercalate ", " organList

numOrZero :: Maybe Int -> Int
numOrZero Nothing = 0
numOrZero (Just a) = a

data Container = Vat Organ | Cooler Organ | Bag Organ
instance Show Container where
    show (Vat organ) = show organ ++ " in a vat"
    show (Cooler organ) = show organ ++ "in a cooler"
    show (Bag organ) = show organ ++ " in a bag"

data Location = Lab | Kitchen | Bathroom deriving Show

organToContainer :: Organ -> Container
organToContainer Brain = Vat Brain
organToContainer Heart = Cooler Heart
organToContainer organ = Bag organ

placeInLocation :: Container -> (Location, Container)
placeInLocation (Vat a) = (Lab, Vat a)
placeInLocation (Cooler a) = (Lab, Cooler a)
placeInLocation (Bag a) = (Kitchen, Bag a)

process :: Organ -> (Location, Container)
process organ = placeInLocation (organToContainer organ)

report :: (Location, Container) -> String
report (location, container) = show container ++ " in the " ++ show location

processAndReport :: Maybe Organ -> String
processAndReport (Just organ) = report (process organ)
processAndReport Nothing = "error, id not found"

processRequest :: Int -> Map.Map Int Organ -> String
processRequest id catalog = processAndReport organ
    where organ = Map.lookup id catalog

reportMaybe :: Maybe (Location, Container) -> String
reportMaybe (Just a) = report a
reportMaybe Nothing = "container not found"


emptyDrawers :: Map.Map Int Organ -> Int
emptyDrawers m = length (filter (\x -> x == Nothing) (getDrawerContents possibleDrawers m))

