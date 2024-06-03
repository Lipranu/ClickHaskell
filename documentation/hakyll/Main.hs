{-# LANGUAGE OverloadedStrings #-}

import GHC.IO.Encoding as Encoding (setLocaleEncoding, utf8)
import Hakyll
import System.FilePath

configuration :: Configuration
configuration = defaultConfiguration{providerDirectory = "documentation"}

main :: IO ()
main = do
  Encoding.setLocaleEncoding Encoding.utf8

  hakyllWith configuration $ do
    match "hakyll/index.html" $ do
      route (constRoute "index.html")
      compile $
        getResourceBody
          >>= applyAsTemplate defaultContext
          >>= loadAndApplyTemplate "hakyll/templates/default.html" defaultContext
          >>= relativizeUrls

    match "hakyll/css/default.css" $ do
      route (constRoute "default.css")
      compile compressCssCompiler

    match "**/*.lhs" $ do
      route $ customRoute ((<.> "html") . takeDirectory . toFilePath)
      compile $
        pandocCompiler
          >>= loadAndApplyTemplate "hakyll/templates/article.html" defaultContext
          >>= loadAndApplyTemplate "hakyll/templates/default.html" defaultContext
          >>= relativizeUrls

    match "hakyll/templates/*" $ compile templateCompiler
