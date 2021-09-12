module ResolverTypes where

import qualified Data.HashTable.IO as HT
import Utils
import qualified Data.Text as T
import qualified Data.Sequence as S
import AST
import qualified TokenHelper as TH
import Data.Maybe

-- ResolveMap
type ResolveMap = HT.BasicHashTable T.Text Bool

createResolveMap :: IO ResolveMap
createResolveMap = HT.new

addToResolveMap :: ResolveMap -> T.Text -> Bool -> IO ResolveMap
addToResolveMap rMap key val  = do
  foundVal <- findInResolveMap key rMap
  if isJust foundVal then do
    print "Variable already defined in scope"
    return rMap
  else do  
    HT.insert rMap key val
    return rMap

updateInResolveMap :: ResolveMap -> T.Text -> Bool -> IO ResolveMap
updateInResolveMap rMap key val = do
  HT.insert rMap key val
  return rMap

findInResolveMap :: AST.TextType -> ResolveMap ->IO (Maybe Bool)
findInResolveMap iden vals = HT.lookup vals iden
  

-- Stack ResolveMap
createScope :: Stack ResolveMap
createScope = createStack

beginScope :: Stack ResolveMap -> ResolveMap -> Stack ResolveMap
beginScope = pushStack

pushScope = beginScope

endScope :: Stack ResolveMap -> (ResolveMap, Stack ResolveMap)
endScope = popStack

popScope = endScope

peekScope :: Stack ResolveMap -> ResolveMap
peekScope = peekStack

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

data ResolverMeta = ResolverMeta {
  depth :: Int
  , varIden :: Maybe T.Text
  , depthMap :: DepthMap
  } deriving (Show)

createResolverMeta = do
  dMap <- createDepthMap
  return ResolverMeta {depth=0, varIden=Nothing, depthMap=dMap}

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

incDepth :: ResolverMeta -> ResolverMeta
incDepth meta = meta{depth=(depth meta+1)}
