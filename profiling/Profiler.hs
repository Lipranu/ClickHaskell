{-# LANGUAGE
    BangPatterns
  , DataKinds
  , DeriveGeneric
  , GeneralizedNewtypeDeriving
  , NumericUnderscores
  , OverloadedStrings
  , TypeApplications
  , MultiParamTypeClasses
  , FlexibleInstances
#-}

module Profiler
  ( main
  ) where

-- External
import Network.HTTP.Client (defaultManagerSettings, newManager)

-- Internal
import ClickHaskell.Client   (WritableInto, ReadableFrom, insertInto, ChCredential(..), selectFrom, select)
import ClickHaskell.Tables   (interpretTable, Table, Column, Columns)
import ClickHaskell.DbTypes
  ( toChType
  , ChUUID, ChDateTime, ChInt32, ChInt64, ChString
  , LowCardinality, Nullable
  )

-- GHC included
import Control.Concurrent (forkIO, killThread, threadDelay)
import Control.Monad (forever, replicateM_)
import Data.ByteString (StrictByteString)
import Data.ByteString.Builder (string8)
import Data.IORef (atomicModifyIORef, newIORef)
import Data.Int (Int32, Int64)
import Data.Word (Word32, Word64)
import Debug.Trace (traceMarkerIO)
import GHC.Conc (atomically, newTVarIO, readTVarIO)
import GHC.Generics (Generic)
import GHC.Natural (Natural)


main :: IO ()
main = do
  traceMarkerIO "Initialization"
  manager <- newManager defaultManagerSettings

  let totalRows = 1_000_000

  threadDelay 1_000_000
  traceMarkerIO "Push data"

  traceMarkerIO "Starting reading"
  selectedData <-
    select
      @(Columns ExampleColumns)
      @ExampleData
      manager
      exampleCredentials
      ("SELECT * FROM generateRandom('a1 Int64, a2 Int32, a3 DateTime, a4 UUID, a5 Int32, a6 LowCardinality(Nullable(String)), a7 LowCardinality(String)', 1, 10, 2) LIMIT " <> (string8 . show) 1_000_000)


  threadDelay 1_000_000
  traceMarkerIO "Starting writing"
  insertInto
    @ExampleTable
    manager
    exampleCredentials
    selectedData

  traceMarkerIO "Completion"
  print $ "5. Writing done. " <> show totalRows <> " rows was written"
  threadDelay 1_000_000

exampleCredentials :: ChCredential
exampleCredentials = MkChCredential "default" "" "http://localhost:8123" "default"


type ExampleTable =
  Table
    "exampleWriteRead"
   '[ Column "a1" ChInt64
    , Column "a2" ChString
    , Column "a3" ChDateTime
    , Column "a4" ChUUID
    , Column "a5" ChInt32
    , Column "a6" (LowCardinality (Nullable ChString))
    , Column "a7" (LowCardinality ChString)
    ]

data ExampleData = MkExampleData
  { a1 :: ChInt64
  , a2 :: StrictByteString
  , a3 :: Word32
  , a4 :: ChUUID
  , a5 :: Int32
  , a6 :: Nullable ChString
  , a7 :: LowCardinality ChString
  }
  deriving (Generic, Show)

type ExampleColumns =
 '[ Column "a1" ChInt64
  , Column "a2" (LowCardinality ChString)
  , Column "a3" ChDateTime
  , Column "a4" ChUUID
  , Column "a5" ChInt32
  , Column "a6" (LowCardinality (Nullable ChString))
  , Column "a7" (LowCardinality ChString)
  ]

instance ReadableFrom (Columns ExampleColumns) ExampleData
instance ReadableFrom ExampleTable ExampleData
instance WritableInto ExampleTable ExampleData

exampleDataSample :: ExampleData
exampleDataSample = MkExampleData
  { a1 = toChType (42 :: Int64)
  , a2 = "text"
  , a4 = toChType (0 :: Word64)
  , a3 = 42
  , a5 = 42
  , a6 = Just "500"
  , a7 = ""
  }