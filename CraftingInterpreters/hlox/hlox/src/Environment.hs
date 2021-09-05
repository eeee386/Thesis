{-# LANGUAGE OverloadedStrings #-}

module Environment where

import qualified Data.HashTable.IO as HT
import qualified Data.Sequence as S
import Data.Maybe
import EvalTypes
import AST
import NativeFunctions

createEnv :: IO HashTable
createEnv = HT.new

createAndPrepGlobalEnv :: IO HashTable
createAndPrepGlobalEnv = do
  globalEnv <- HT.new
  -- TODO: Fix global functions
  addUpdateIdentifier "clock" (FUNC_DEC_EVAL
                               "clock"
                               0
                               (PARAMETERS S.empty)
                               (NATIVE_FUNC_STMT (CLOCK clock)) (CLOSURE S.empty)) globalEnv

createGlobalEnvironment :: IO Environments
createGlobalEnvironment = S.singleton <$> createAndPrepGlobalEnv

createLocalEnvironment :: Environments -> IO Environments
createLocalEnvironment env = do
  newEnv <- createEnv
  return (env S.|> newEnv)

getLocalEnvironment :: Environments -> HashTable
getLocalEnvironment env = S.index env (S.length env-1)

deleteLocalEnvironment :: Environments -> Environments
deleteLocalEnvironment env = S.deleteAt (S.length env-1) env

updateLocalEnvironment :: Environments -> HashTable -> Environments
updateLocalEnvironment env locEnv = newEnvs S.|> locEnv
  where newEnvs = deleteLocalEnvironment env

addUpdateIdentifier :: AST.TextType -> EVAL -> HashTable -> IO HashTable
addUpdateIdentifier iden value vals = do
   HT.insert vals iden value
   return vals

getValueOfIdentifier :: AST.TextType -> HashTable -> IO (Maybe EVAL)
getValueOfIdentifier iden vals = do
  HT.lookup vals iden

addIdentifierToEnvironment :: AST.TextType -> EVAL -> Environments -> IO Environments
addIdentifierToEnvironment iden value env = do
   let actEnv = getLocalEnvironment env
   newActEnv <- addUpdateIdentifier iden value actEnv
   return (updateLocalEnvironment env newActEnv)
   
updateIdentifierInSpecificEnvironment :: AST.TextType -> EVAL -> Environments -> Int -> IO Environments
updateIdentifierInSpecificEnvironment iden value env index = do
  let locEnv = S.index env index
  let delEnv = S.deleteAt index env
  HT.insert locEnv iden value
  return (S.insertAt index locEnv delEnv)
  
  
updateIdentifierToEnvironment :: AST.TextType -> EVAL -> Environments -> IO (Environments, Bool)
updateIdentifierToEnvironment iden value env = do
  values <- mapM (getValueOfIdentifier iden) env
  let index = S.findIndexR isJust values
  if 
    isJust index 
  then do
    newEnv <- updateIdentifierInSpecificEnvironment iden value env (fromJust index) 
    return (newEnv, True) 
  else
    return (env, False) 

findValueOfIdentifier :: AST.TextType -> Environments -> IO (Maybe EVAL)
findValueOfIdentifier iden env = do
  values <- mapM (getValueOfIdentifier iden) env
  let index = S.findIndexR isJust values
  if isJust index then return (S.index values (fromJust index)) else return Nothing


-- Add sequence of closure function (names), 
-- the length of that will decide how much to add to the function declaration closure prop
-- when declared. (From the current env which already has the functions )

-- I think we should delete the env when we finish the function call,
-- and the declared inner function's closure prop should save it into its closure prop.
-- And whenever we call the closured function it will add its closure to the current environment 
data META = META {
  env :: Environments
  , isInFunction :: Bool
  , isInLoop :: Bool
                 } deriving Show


createGlobalMeta :: IO META
createGlobalMeta = do
  e <- createGlobalEnvironment
  return META {env=e, isInFunction=False, isInLoop=True}


updateMetaWithLocalEnv :: META -> IO META
updateMetaWithLocalEnv meta = do
  locEnv <- createLocalEnvironment (env meta)
  return meta {env=locEnv}

deleteLocalEnvFromMeta :: META -> META
deleteLocalEnvFromMeta meta = meta {env=deleteLocalEnvironment (env meta)}


addIdentifierToMetaEnv :: AST.TextType -> EVAL -> META -> IO META
addIdentifierToMetaEnv iden value meta = do
  let oldEnv = env meta
  newEnv <- addIdentifierToEnvironment iden value oldEnv
  return meta {env=newEnv}

updateIdentifierToMetaEnv ::  AST.TextType -> EVAL -> META -> IO (META, Bool)
updateIdentifierToMetaEnv iden value meta = do
  let oldEnv = env meta
  (newEnv, flag) <- updateIdentifierToEnvironment iden value oldEnv
  return (meta {env=newEnv},flag)

findValueInMetaEnv ::  AST.TextType -> META -> IO (Maybe EVAL)
findValueInMetaEnv iden meta = do
  findValueOfIdentifier iden (env meta)


updateMetaWithClosure :: META -> CLOSURE -> META
updateMetaWithClosure meta (CLOSURE clos) = meta{env=((env meta) S.>< clos)}

breakClosureFromMeta :: META -> Int -> (META, CLOSURE)
breakClosureFromMeta meta numberOfClosure = (meta{env=newEnv}, CLOSURE closEnv)
  where (newEnv, closEnv) = S.splitAt (S.length (env meta) - numberOfClosure) (env meta)
