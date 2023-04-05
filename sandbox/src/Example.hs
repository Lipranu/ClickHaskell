{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeOperators #-}
module Example where

import Data.Text (Text)
import GHC.Generics           (Generic)

import ClickHaskell           (tsvSelectQuery)
import ClickHaskell.ChTypes   (ChString, ChInt64, ChUUID, ChDateTime)
import ClickHaskell.TableDsl  (Table, DefaultColumn, MergeTree, HasChSchema, InDatabase, showCreateTable, SampledBy, EqualityWith)


-- 1. Describe table

type ExampleTable =
  Table
    "example"
    '[
       DefaultColumn "channel_name" ChString
     , DefaultColumn "clientId"     ChInt64
     , DefaultColumn "someField"    ChDateTime
     , DefaultColumn "someField2"   ChUUID
     ]
    MergeTree
    '["clientId", "someField2"]
    '["clientId"]


-- |
-- >>> showCreateExample
-- "CREATE TABLE example.example (channel_name String, clientId Int64, someField DateTime, someField2 UUID) Engine=MergeTree PARTITION BY (clientId) ORDER BY (clientId, client)"
showCreateExample :: String
showCreateExample = showCreateTable @(InDatabase "example" ExampleTable)


-- |
-- >>> showSelect
-- "SELECT channel_name,clientId,someField,someField2 FROM example.example WHERE fieldName=\"const\" AND  FORMAT TSV"
showSelect :: Text
showSelect = tsvSelectQuery @(("fieldName" `SampledBy` EqualityWith "const") ExampleData) @(InDatabase "example" ExampleTable)


-- 2. Separate data you will work with
data ExampleData = ExampleData
  { channel_name :: ChString
  , clientId     :: ChInt64
  , someField    :: ChDateTime
  , someField2   :: ChUUID
  }
  deriving (Generic, HasChSchema, Show)