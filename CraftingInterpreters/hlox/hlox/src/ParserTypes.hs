module ParserTypes where

import AST
import TokenHelper
import qualified Data.Sequence as S


data ParserMeta = ParserMeta {
    declaration :: DECLARATION
  , tokensLeft :: S.Seq Token
  , currentVarId :: Int
  }

createParserMeta :: S.Seq Token -> ParserMeta
createParserMeta tokens = ParserMeta{declaration=SKIP_DEC, tokensLeft=tokens, currentVarId=0} 


updateParserMeta :: DECLARATION -> S.Seq Token -> Int -> ParserMeta -> ParserMeta
updateParserMeta dec tokens cVarId meta = meta{declaration=dec, tokensLeft=tokens, currentVarId=cVarId} 

updateVarId ::  ParserMeta -> ParserMeta
updateVarId meta = meta{currentVarId=currentVarId meta+1}

updateTokens :: S.Seq Token -> ParserMeta -> ParserMeta
updateTokens tokens meta = meta{tokensLeft=tokens}

updateDec :: DECLARATION -> ParserMeta -> ParserMeta
updateDec dec meta = meta{declaration=dec}

updateDecAndTokens ::  DECLARATION -> S.Seq Token -> ParserMeta -> ParserMeta
updateDecAndTokens dec tokens meta = meta{declaration=dec, tokensLeft=tokens}
