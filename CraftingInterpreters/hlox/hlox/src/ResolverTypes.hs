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

addUpdateToResolveMap :: ResolveMap -> T.Text -> Bool -> IO ResolveMap
addUpdateToResolveMap rMap key val  = do
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
findInDepthMap expr vals = HT.lookup vals expr

