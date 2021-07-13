module Glitch(randomReplaceBytes, randomSortSection, randomReplaceBytes, randomSortSection, randomReplaceBytes) where
import qualified Data.ByteString as B
import qualified Data.ByteString.Char8 as BC
import System.Random


intToChar :: Int -> Char 
intToChar int = toEnum safeInt
    where safeInt = int `mod` 255

intToBC :: Int -> BC.ByteString 
intToBC int = BC.pack [intToChar int]

replaceByte :: Int -> Int -> BC.ByteString -> BC.ByteString 
replaceByte loc charVal bytes = mconcat [before, newChar, after]
    where (before, rest) = BC.splitAt loc bytes
          after = BC.drop 1 rest
          newChar = intToBC charVal

randomReplaceBytes :: BC.ByteString -> IO BC.ByteString 
randomReplaceBytes bytes = do
    let bytesLength = BC.length bytes
    location <- randomRIO (1, bytesLength) 
    charVal <- randomRIO (0, 255)
    return (replaceByte location charVal bytes)


sortSection :: Int -> Int -> BC.ByteString -> BC.ByteString 
sortSection start size bytes = mconcat [before, changed, after]
    where (before, rest) = BC.splitAt start bytes
          (target, after) = BC.splitAt size rest
          changed = BC.reverse (BC.sort target)

randomSortSection :: BC.ByteString -> IO BC.ByteString 
randomSortSection bytes = do
    let sectionSize = 25
    let bytesLength = BC.length bytes
    start <- randomRIO (0, bytesLength - sectionSize)
    return (sortSection start sectionSize bytes)

reverseSection :: Int -> Int -> BC.ByteString -> BC.ByteString 
reverseSection start size bytes = mconcat [before, changed, after]
    where (before, rest) = BC.splitAt start bytes
          (target, after) = BC.splitAt size rest
          changed = BC.reverse target

randomReverseSection :: BC.ByteString -> IO BC.ByteString 
randomReverseSection bytes = do
    let sectionSize = 25
    let bytesLength = BC.length bytes
    start <- randomRIO (0, bytesLength - sectionSize)
    return (reverseSection start sectionSize bytes)