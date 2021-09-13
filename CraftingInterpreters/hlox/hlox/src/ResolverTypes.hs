{-# LANGUAGE OverloadedStrings #-}

module ResolverTypes where

import qualified Data.HashTable.IO as HT
import Utils
import qualified Data.Text as T
import qualified Data.Sequence as S
import AST
import qualified TokenHelper as TH
import Data.Maybe

-- Depth Map
type DepthMap = HT.BasicHashTable T.Text Int

createDepthMap :: IO DepthMap
createDepthMap = HT.new

addUpdateToDepthMap :: DepthMap -> T.Text -> Int -> IO DepthMap
addUpdateToDepthMap rMap key val = do
  HT.insert rMap key val
  return rMap

findInDepthMap :: T.Text -> DepthMap -> IO (Maybe Int)
findInDepthMap iden vals = do
  val <- HT.lookup vals iden
  return val

-- ResolverError
data ResolverError = RESOLVER_ERROR T.Text (S.Seq TH.Token) deriving Show



-- ResolverMeta
data ResolverMeta = ResolverMeta {
  depth :: Int
  , varIden :: Maybe T.Text
  , depthMap :: DepthMap
  , rErrors :: S.Seq ResolverError
  } deriving (Show)

createResolverMeta = do
  dMap <- createDepthMap
  return ResolverMeta {depth=0, varIden=Nothing, depthMap=dMap, rErrors=S.empty}

updateMapInMeta :: ResolverMeta -> T.Text -> IO ResolverMeta
updateMapInMeta meta iden = do
  dMap <- addUpdateToDepthMap (depthMap meta) iden (depth meta)
  return meta{depthMap=dMap, varIden=Just iden}


checkIfResolverError :: ResolverMeta -> T.Text -> IO Bool
checkIfResolverError meta iden
  | Just  iden /= (varIden meta) = return False
  | otherwise = do
    maybeDepth  <- findInDepthMap iden (depthMap meta)
    return (maybeDepth == Just (depth meta))

checkIfVarAlreadyAdded :: ResolverMeta -> T.Text -> IO Bool
checkIfVarAlreadyAdded meta iden = do
  maybeDepth <- findInDepthMap iden (depthMap meta)
  return (isJust maybeDepth)
  
incDepth :: ResolverMeta -> IO ResolverMeta
incDepth meta = return meta{depth=(depth meta+1)}

decDepth :: ResolverMeta -> IO ResolverMeta
decDepth meta = return meta{depth=(depth meta-1)}

cleanVarMeta :: ResolverMeta -> IO ResolverMeta
cleanVarMeta meta = return meta{varIden=Nothing}

addError :: ResolverError -> ResolverMeta -> IO ResolverMeta
addError error meta = return meta{rErrors=(rErrors meta S.|> error)}

checkHandleIfAlreadyAdded :: (ResolverMeta -> T.Text -> IO ResolverMeta) -> T.Text -> ResolverMeta -> IO ResolverMeta
checkHandleIfAlreadyAdded f iden meta  = do
   res <- checkIfVarAlreadyAdded meta iden
   if res then do
     addError (RESOLVER_ERROR "Variable already added in scope" S.empty) meta
   else f meta iden
