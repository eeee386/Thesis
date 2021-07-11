data User = User
  { name    :: String
  , gamerId :: Int
  , score   :: Int
  } deriving (Show)

maybeUsername :: Maybe String
maybeUsername = Just "Sue"

maybeGamerId :: Maybe Int
maybeGamerId = Just 1337

maybeScore :: Maybe Int
maybeScore = Just 9001

readInt :: IO Int 
readInt = read <$> getLine 

main :: IO()
main = do
    putStrLn "Enter a usernam, id, and score"
    user <- User <$> getLine <*> readInt <*> readInt
    print user