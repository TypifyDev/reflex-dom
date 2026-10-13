{-# LANGUAGE CPP #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RankNTypes #-}
-- |
-- Effectful port of upstream @Reflex.Dom.Internal@.
--
-- Upstream this module bundled two things: a CPP-selected platform
-- runner @run :: JSM () -> IO ()@ (jsaddle-warp / wkwebview / android /
-- wasm / webkit2gtk / ghcjs), and a @mainWidget@ family that wrapped
-- @attachWidget@ under that @run@.
--
-- In the Effectful port, 'Reflex.Effectful.DomHost' already provides the
-- full @mainWidget*@ family with the current @ImmediateWidget x es@
-- effect surface (via 'Reflex.Effectful.DomHost.withDomHost', which is
-- jsaddle-warp on GHC). We re-export those directly here so downstream
-- consumers that do @import Reflex.Dom (mainWidget, …)@ get a working
-- entrypoint without importing @reflex-dom-core-effectful@ explicitly.
--
-- The CPP-selected 'run' is preserved (a) for callers using it directly
-- as @run $ jsm@ outside of the @mainWidget@ family, and (b) as the
-- structural slot for per-platform ports still landing — Android,
-- iOS/WKWebView, WASM, webkit2gtk. Today only the jsaddle-warp path is
-- fully live end-to-end; the other branches compile 'run' but their
-- surrounding Effectful runtime is not yet complete.
module Reflex.Dom.Internal
  ( module Main
  , run
  , mainWidget
  , mainWidgetInBody
  , mainWidgetWithHead
  , mainWidgetWithCss
  , mainWidgetInElementById
  ) where

import Data.ByteString (ByteString)
import Data.Text (Text)

import Reflex.Effectful.DomHost as Main hiding
       ( mainWidget, mainWidgetWithHead
       , mainWidgetWithCss, mainWidgetInElementById
       )
import qualified Reflex.Effectful.DomHost as Host

#if defined(ghcjs_HOST_OS)
run :: a -> a
run = id
#elif defined(MIN_VERSION_jsaddle_warp)
import Language.Javascript.JSaddle (JSM)
import qualified Language.Javascript.JSaddle.Warp as JW
import System.Environment (lookupEnv)

run :: JSM () -> IO()
run jsm = do
  port <- maybe 3003 read <$> lookupEnv "JSADDLE_WARP_PORT"
  putStrLn $ "Running jsaddle-warp server on port " <> show port
  JW.run port jsm

#elif defined(MIN_VERSION_jsaddle_wkwebview)
#if defined(ios_HOST_OS)
import Data.Default
import Data.Monoid ((<>))
import Language.Javascript.JSaddle (JSM)
import Language.Javascript.JSaddle.WKWebView (run', mainBundleResourcePath)
import Language.Javascript.JSaddle.WKWebView.Internal (jsaddleMainHTMLWithBaseURL)

-- TODO: upstream to jsaddle-wkwebview
run :: JSM () -> IO ()
run jsm = do
  let indexHtml = "<!DOCTYPE html><html><head></head><body></body></html>"
  baseUrl <- mainBundleResourcePath >>= \case
    Nothing -> do
      putStrLn "Reflex.Dom.run: unable to find main bundle resource path. Assets may not load properly."
      return ""
    Just p -> return $ "file://" <> p <> "/index.html"
  run' def $ jsaddleMainHTMLWithBaseURL indexHtml baseUrl jsm

#else
import Language.Javascript.JSaddle.WKWebView (run)
#endif
-- MTL branch, agent-C will address: this ANDROID branch references
-- MTL-era @Reflex.Dom.Android.MainWidget@ and @Android.HaskellActivity@
-- which have not yet been ported into the Effectful stack. The Android
-- bootstrap belongs to agent-C's scope; we leave the imports intact so
-- the CPP dispatch structure is preserved and the eventual Android
-- port has a well-defined slot to land into.
#elif defined(ANDROID)
import Android.HaskellActivity
import Control.Monad
import Control.Monad.IO.Class (liftIO, MonadIO)
import Control.Concurrent
import Language.Javascript.JSaddle (JSM)
import Data.Default
import Data.IORef
import Data.Maybe
import Data.String
import Reflex.Dom.Android.MainWidget
import System.IO
import System.IO.Unsafe
import Language.Javascript.JSaddle (JSM, eval)

run :: JSM () -> IO ()
run jsm = do
  hSetBuffering stdout LineBuffering
  hSetBuffering stderr LineBuffering
  continueWithCallbacks $ def
    { _activityCallbacks_onCreate = \_ -> do
        a <- getHaskellActivity
        let startPage = fromString "https://appassets.androidplatform.net/index.html"
        startMainWidget a startPage jsm
    , _activityCallbacks_onBackPressed = triggerBackButton
    }
  forever $ threadDelay 1000000000

triggerBackButton :: MonadIO m => m ()
triggerBackButton = withGlobalJSExecutor goBack

#elif defined(MIN_VERSION_jsaddle_wasm)
import qualified Language.Javascript.JSaddle.Wasm as Wasm (run)
import Language.Javascript.JSaddle (JSM)
run :: JSM () -> IO ()
run = Wasm.run

#elif defined(MIN_VERSION_jsaddle_webkit2gtk)
import Language.Javascript.JSaddle.WebKitGTK (run)

#else
import qualified GHC.TypeLits as GHC
run :: GHC.TypeError (GHC.Text "Attempting to compile reflex-dom for unsupported platform")
run = error "unreachable"
#endif

-- Delegate the @mainWidget@ family straight to
-- 'Reflex.Effectful.DomHost' (jsaddle-warp via 'withDomHost'). See the
-- module docstring for why the CPP-selected 'run' is preserved above
-- but not used by these wrappers today.

mainWidget :: (forall x es. ImmediateWidget x es) -> IO ()
mainWidget = Host.mainWidget

mainWidgetInBody :: (forall x es. ImmediateWidget x es) -> IO ()
mainWidgetInBody = Host.mainWidget

mainWidgetWithHead
  :: (forall x es. ImmediateWidget x es)
  -> (forall x es. ImmediateWidget x es)
  -> IO ()
mainWidgetWithHead = Host.mainWidgetWithHead

mainWidgetWithCss
  :: ByteString
  -> (forall x es. ImmediateWidget x es)
  -> IO ()
mainWidgetWithCss = Host.mainWidgetWithCss

mainWidgetInElementById
  :: Text
  -> (forall x es. ImmediateWidget x es)
  -> IO ()
mainWidgetInElementById = Host.mainWidgetInElementById
