{-# LANGUAGE OverloadedStrings #-}

module Environment where

import qualified Data.HashTable.IO as HT
import qualified Data.Sequence as S
import Data.Maybe

import EvalTypes
import AST

type HashTable = HT.BasicHashTable AST.TextType EVAL
type Environments = S.Seq HashTable

createEnv :: IO HashTable
createEnv = HT.new

createGlobalEnvironment :: IO Environments
createGlobalEnvironment = S.singleton <$> createEnv

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

