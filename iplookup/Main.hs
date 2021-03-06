module Main where

import Options.Applicative as Opt
import Control.Exception.Safe
import System.Exit
import Data.Semigroup

import Types
import ParseIP
import LookupIP

data Params = Params
                FilePath
                String

mkParams :: Opt.Parser Params
mkParams = Params
             <$> argument str (metavar "FILE" <> help "IP range database") 
             <*> argument str (metavar "IP" <> help "IP address to check")

run :: Params -> IO ()
run (Params fp ipstr) = do
  iprs <- parseIPRanges <$> readFile fp
  case (iprs, parseIP ipstr) of
    (_, Nothing) -> throw (InvalidIP ipstr)
    (Left pe, _) -> throw (LoadIPRangesError pe)
    (Right iprdb, Just ip) -> processIP iprdb ip

processIP :: IPRangeDB -> IP -> IO ()
processIP iprdb ip
  | lookupIP iprdb ip = putStrLn "YES"
  | otherwise = putStrLn "NO"

main = (execParser opts >>= run)
       `catches` [Handler parserExit]
  where
    opts =
      info (mkParams <**> helper)
           (fullDesc <>
            progDesc ("Answers YES/NO depending on whether " ++
                      "an IP address belongs to the IP range database"))
    parserExit :: ExitCode -> IO ()
    parserExit _ = pure ()
