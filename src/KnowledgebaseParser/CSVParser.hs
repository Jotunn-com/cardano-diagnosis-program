{-# LANGUAGE OverloadedStrings #-}

module KnowledgebaseParser.CSVParser where

import Control.Applicative

import Data.Attoparsec.Text.Lazy

import Data.Text.Lazy (Text)
import qualified Data.Text.Lazy as LT

import Types

import Prelude hiding (takeWhile)

insideQuotes :: Parser Text
insideQuotes =
   LT.append <$> (LT.fromStrict <$> takeWhile (/= '"'))
            <*> (LT.concat <$> many (LT.cons <$> dquotes <*> insideQuotes))
   <?> "inside of double quotes"
   where
      dquotes =
         string "\"\"" >> return '"'
         <?> "paired double quotes"

quotedField :: Parser Text
quotedField =
   char '"' *> insideQuotes <* char '"'
   <?> "quoted field"

parseErrorCode :: Parser ErrorCode
parseErrorCode = 
        (string "FileNotFound"      >> return FileNotFound)
    <|> (string "TimeSync"          >> return TimeSync)
    <|> (string "DBError"           >> return DBError)
    <|> (string "ShortStorage"      >> return ShortStorage)
    <|> (string "NetworkError"      >> return NetworkError)
    <|> (string "ConnectionRefused" >> return ConnectionRefused)
    <|> (string "Error"             >> return Error)
    <|> (string "Unknown"           >> return Unknown)

parseKnowledge :: Parser Knowledge
parseKnowledge = do
    e <- quotedField
    char ','
    char '"'
    c <- parseErrorCode
    char '"'
    char ','
    p <- quotedField
    char ','
    s <- quotedField
    return $ Knowledge e c p s

parseKnowLedgeBase :: Parser KnowledgeBase
parseKnowLedgeBase = many $ parseKnowledge <* endOfLine