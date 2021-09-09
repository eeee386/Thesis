module ResolverTypes where

import qualified Data.HashTable.IO as HT
import Utils
import qualified Data.Text as T
import qualified Data.Sequence as S
import AST


type ResolveMap = HT.BasicHashTable T.Text Bool

createMap :: IO ResolveMap
createMap = HT.new

addUpdateToMap :: ResolveMap -> T.Text -> Bool -> IO ResolveMap
addUpdateToMap rMap key val  = HT.insert rMap  key val

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

resolveMulti :: Stack ResolveMap -> S.Seq DECLARATION -> IO (Stack ResolveMap)
resolveMulti s decs
  | S.null decs = return s
  | otherwise = resolve s dec
  where dec = S.index decs 0

resolve ::Stack ResolveMap -> DECLARATION -> IO (Stack ResolveMap)
resolve scopes (DEC_STMT (BLOCK_STMT decs)) = do
  rMap <- createMap
  let startScopes = beginScope scopes rMap
  resScopes <- resolveMulti startScopes decs
  let endScopes = endScope resScopes
  return (snd endScopes)
resolve scopes (DEC_VAR (VAR_DEC_DEF (TH.IDENTIFIER iden) expr)) = do
  if
    null scopes
  then do
   return scopes
  else do
--declare
    let (scope,scopes) = popScope scopes
    addedScope <- addUpdateToMap scope iden False
-- here resolve expr
-- define
    updatedScope <- addUpdateToMap addedToScope iden True
    return (pushScope scopes updatedScope



resolveExpression :: Stack ResolveMap -> EXPRESSION -> IO (Stack ResolveMap)
