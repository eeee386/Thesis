import Data.Map as Map

type UserName = String

type GamerID = Int

type Credits = Int

userNameDB :: Map.Map GamerID UserName
userNameDB = Map.fromList
  [ (1, "nYarlathoTep")
  , (2, "KINGinYELLOW")
  , (3, "dagon1997")
  , (4, "rcarter1919")
  , (5, "xCTHULHUx")
  , (6, "yogSOThoth")
  ]

creditsDB :: Map.Map UserName Credits
creditsDB = Map.fromList
  [ ("nYarlathoTep", 2000)
  , ("KINGinYELLOW", 15000)
  , ("dagon1997"   , 300)
  , ("rcarter1919" , 12)
  , ("xCTHULHUx"   , 50000)
  , ("yogSOThoth"  , 150000)
  ]

-- Goal:
{-
creditsFromId :: GamerId -> Maybe PlayerCredits
-}

-- We need to hook up these two functions:

lookupUserName :: GamerID -> Maybe UserName
lookupUserName gamerID = Map.lookup gamerID userNameDB

lookupCredits :: UserName -> Maybe Credits
lookupCredits username = Map.lookup username creditsDB

-- A function to connect these would look like this, concrete & generally:
{-
                 Maybe UserName -> (UserName -> Maybe Credits) -> Maybe Credits
Applicative f => f     a        -> (a        -> f     b)       -> f     b
-}

-- One way is to make a wrapper around the 2nd function:
altLookupCredits :: Maybe UserName -> Maybe Credits
altLookupCredits Nothing         = Nothing
altLookupCredits (Just username) = lookupCredits username

-- This works but is clumsy:
{-
creditsFromID 1  -- Just 2000
creditsFromID 10 -- Nothing
-}
creditsFromID :: GamerID -> Maybe Credits
creditsFromID gamerID = altLookupCredits (lookupUserName gamerID)

-- QC1

-- It returns a nested Maybe:
{-
creditsFromIDStrange 1 -- Just (Just 2000)
-}
creditsFromIDStrange :: GamerID -> Maybe (Maybe Credits)
creditsFromIDStrange gamerID = pure lookupCredits <*> lookupUserName gamerID

creditsFromId :: GamerID -> Maybe Credits
creditsFromId id = lookupUserName id >>= lookupCredits

type WillCoID = Int

gamerIDDB :: Map.Map WillCoID GamerID
gamerIDDB =
  Map.fromList [(1001, 1), (1002, 2), (1003, 3), (1004, 4), (1005, 5), (1006, 6)]

lookupGamerID :: WillCoID -> Maybe GamerID
lookupGamerID willCoID = Map.lookup willCoID gamerIDDB

creditsFromWCId :: WillCoID -> Maybe Credits
creditsFromWCId id = lookupGamerID id >>= lookupUserName >>= lookupCredits

allFmapM :: Monad m => (a -> b) -> m a -> m b
allFmapM f a = a >>= (\b -> return (f b))

allApp :: Monad m => m (a -> b) -> m a -> m b
allApp f a = f >>= (\fu -> fu a >>= (\b -> return (fu b)))