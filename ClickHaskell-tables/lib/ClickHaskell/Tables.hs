{-# LANGUAGE
    AllowAmbiguousTypes
  , DataKinds
  , NamedFieldPuns
  , OverloadedStrings
  , TypeFamilyDependencies
  , UndecidableInstances
#-}

module ClickHaskell.Tables
(
-- * Tables
-- ** Interpreter
  InterpretableTable(..)

-- ** Table
, Table

-- ** View
, View, renderView
, Parameter, mkParameter


-- * Columns
-- ** HasColumns helper class
, Columns
, HasColumns(..)

-- ** Column
, Column

-- ** Column subtypes
, Alias
, Default

-- ** Compilers
, CompiledColumn(..)
) where


-- Internal
import ClickHaskell.DbTypes (ToQueryPart(..), IsChType(ToChTypeName, IsWriteOptional))


-- GHC included
import Data.ByteString.Builder as BS (Builder, byteString, stringUtf8)
import Data.ByteString.Char8   as BS8 (pack)
import Data.Data               (Proxy (Proxy))
import Data.Kind               (Type)
import GHC.TypeLits            (ErrorMessage (..), Symbol, KnownSymbol, symbolVal)


-- * Tables
-- ** Interpreter

class
  HasColumns table
  =>
  InterpretableTable table
  where

  type TableInterpreter table = result | result -> table
  interpretTable :: TableInterpreter table




-- ** Table

data Table
  (name :: Symbol)
  (columns :: [Type])








-- ** View

data View
  (name :: Symbol)
  (columns :: [Type])
  (parameters :: [Type])
  = MkView
    { viewName :: Builder
    , inpterpretedParameters :: [Builder]
    }




newtype Parameter (name :: Symbol) (chType :: Type) =
  MkParameter
    { renderedParameter :: Builder
    }


mkParameter ::
  forall name chType
  .
  ( KnownSymbol name
  , ToQueryPart chType
  ) =>
  chType -> Parameter name chType
mkParameter chType =
  MkParameter
    { renderedParameter = (BS.byteString . BS8.pack . symbolVal @name) Proxy <> "=" <> toQueryPart chType
    }


{- |
Takes evaluated View and renders it

>>> let {param1="param1=['1']"; param2="param2=['2']"}

>>> renderView MkView{viewName="viewExample", inpterpretedParameters=[]}
"viewExample"

>>> renderView MkView{viewName="viewExample2", inpterpretedParameters=[param1]}
"viewExample2(param1=['1'])"

>>> renderView MkView{viewName="viewExample3", inpterpretedParameters=[param1, param2]}
"viewExample3(param2=['2'], param1=['1'])"
-}
renderView :: View name columns parameters -> Builder
renderView (MkView{viewName, inpterpretedParameters}) = viewName <> renderTableParameters inpterpretedParameters


renderTableParameters :: [Builder] -> Builder
renderTableParameters (parameter:ps) = "(" <> foldr (\p1 p2 -> p1 <> ", " <> p2) parameter ps <> ")"
renderTableParameters []             = ""


instance
  ( KnownSymbol name
  ) => InterpretableTable (View name columns '[])
  where
  type TableInterpreter (View name columns '[]) = View name columns '[]
  interpretTable =
    MkView
      { viewName = (BS.byteString . BS8.pack . symbolVal @name) Proxy
      , inpterpretedParameters = []
      }


instance
  ( KnownSymbol name
  ) => InterpretableTable (View name columns '[Parameter paramName (chType :: Type)])
  where
  type TableInterpreter (View name columns '[Parameter paramName chType]) = Parameter paramName chType -> View name columns '[]
  interpretTable MkParameter{renderedParameter} =
    MkView
      { viewName = (BS.byteString . BS8.pack . symbolVal @name) Proxy
      , inpterpretedParameters = [renderedParameter]
      }


instance
  ( KnownSymbol name
  ) => InterpretableTable 
    ( View
      name
      columns
     '[ Parameter paramName chType
      , Parameter paramName2 chType2
      ]
    )
  where

  type TableInterpreter
    ( View
      name
      columns
     '[ Parameter paramName chType
      , Parameter paramName2 chType2
      ]
    ) 
    =  Parameter paramName chType
    -> Parameter paramName2 chType2
    -> View name columns '[]
  interpretTable parameter1 parameter2 =
    MkView
      { viewName = (BS.byteString . BS8.pack . symbolVal @name) Proxy
      , inpterpretedParameters = [renderedParameter parameter1, renderedParameter parameter2]
      }


instance
  ( KnownSymbol name
  ) => InterpretableTable 
    ( View
      name
      columns
     '[ Parameter paramName chType
      , Parameter paramName2 chType2
      , Parameter paramName3 chType3
      ]
    )
  where

  type TableInterpreter
    ( View
      name
      columns
     '[ Parameter paramName chType
      , Parameter paramName2 chType2
      , Parameter paramName3 chType3
      ]
    )
    =  Parameter paramName chType
    -> Parameter paramName2 chType2
    -> Parameter paramName3 chType3
    -> View name columns '[]
  interpretTable parameter1 parameter2 parameter3 =
    MkView
      { viewName = (BS.byteString . BS8.pack . symbolVal @name) Proxy
      , inpterpretedParameters = [renderedParameter parameter1, renderedParameter parameter2, renderedParameter parameter3]
      }


instance
  ( KnownSymbol name
  ) => InterpretableTable 
    ( View
      name
      columns
     '[ Parameter paramName chType
      , Parameter paramName2 chType2
      , Parameter paramName3 chType3
      , Parameter paramName4 chType4
      ]
    )
  where

  type TableInterpreter
    ( View
      name
      columns
     '[ Parameter paramName chType
      , Parameter paramName2 chType2
      , Parameter paramName3 chType3
      , Parameter paramName4 chType4
      ]
    )
    =  Parameter paramName chType
    -> Parameter paramName2 chType2
    -> Parameter paramName3 chType3
    -> Parameter paramName4 chType4
    -> View name columns '[]
  interpretTable parameter1 parameter2 parameter3 parameter4 =
    MkView
      { viewName = (BS.byteString . BS8.pack . symbolVal @name) Proxy
      , inpterpretedParameters =
        [ renderedParameter parameter1
        , renderedParameter parameter2
        , renderedParameter parameter3
        , renderedParameter parameter4
        ]
      }








-- * Columns

-- ** HasColumns helper class

data Columns (columns :: [Type])

class HasColumns hasColumns where
  type GetColumns hasColumns :: [Type]

instance HasColumns (View name columns params) where
  type GetColumns (View _ columns _) = columns

instance HasColumns (Table name columns) where
  type GetColumns (Table _ columns) = columns

instance HasColumns (Columns columns) where
  type GetColumns (Columns columns) = columns 




-- ** Column declaration

{- |
Column declaration

Examples:

@
type MyColumn = Column "myColumn" ChString
type MyColumn = Column "myColumn" ChString -> Alias
type MyColumn = Column "myColumn" ChString -> Default
@
-}
data Column (name :: Symbol) (columnType :: Type)

instance
  ( IsChType columnType
  , KnownSymbol name
  , KnownSymbol (ToChTypeName columnType)
  ) => CompiledColumn (Column name columnType)
  where
  type GetColumnName (Column name columnType) = name
  renderColumnName = (stringUtf8 . symbolVal @name) Proxy

  type GetColumnType (Column name columnType) = columnType
  renderColumnType = (stringUtf8 . symbolVal @(ToChTypeName columnType)) Proxy 

  type WritableColumn (Column _ _) = Nothing

  type WriteOptionalColumn (Column name columnType) = IsWriteOptional columnType




-- ** Columns properties

{- |
Column that refers to another column.

Can be only readed.

Example:

@
type MyColumn = Column "myColumn" ChString -> Alias
@
-}
data Alias

instance
  CompiledColumn (Column name columnType)
  =>
  CompiledColumn (Column name columnType -> Alias)
  where
  type GetColumnName (Column name columnType -> Alias) = GetColumnName (Column name columnType)
  renderColumnName = renderColumnName @(Column name columnType)

  type GetColumnType (Column name columnType -> Alias) = GetColumnType (Column name columnType)
  renderColumnType = renderColumnType @(Column name columnType)

  type WritableColumn (Column name columnType -> Alias) =
    Just
      (    'Text "You are trying insert into Alias column \"" :<>: 'Text name :<>: 'Text "\""
      :$$: 'Text "You can't do this. Read about Alias columns"
      )

  type WriteOptionalColumn (Column name columnType -> Alias) = False


{- |
Column which value could be evaluated when it's not mentioned.

Not required for writing.

Example:

@
type MyColumn = Column "myColumn" ChString -> Default
@
-}
data Default

instance
  CompiledColumn (Column name columnType)
  =>
  CompiledColumn (Column name columnType -> Default)
  where
  type GetColumnName (Column name columnType -> Default) = GetColumnName (Column name columnType)
  renderColumnName = renderColumnName @(Column name columnType)

  type GetColumnType (Column name columnType -> Default) = GetColumnType (Column name columnType)
  renderColumnType = renderColumnType @(Column name columnType)

  type WritableColumn (Column name columnType -> Default) = Nothing

  type WriteOptionalColumn (Column name columnType -> Default) = True




-- ** Compiler

class
  IsChType (GetColumnType columnDescription)
  =>
  CompiledColumn columnDescription where
  type GetColumnName columnDescription :: Symbol
  renderColumnName :: Builder

  type GetColumnType columnDescription :: Type
  renderColumnType :: Builder

  type WritableColumn    columnDescription :: Maybe ErrorMessage
  type WriteOptionalColumn columnDescription :: Bool
