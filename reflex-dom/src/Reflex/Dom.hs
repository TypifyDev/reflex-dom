-- Disable haddocks on this module due to a bug on haddocks when selectively
-- reexporting on ghc > 8.2.
-- https://github.com/haskell/haddock/issues/979
{-# OPTIONS_HADDOCK hide, prune, ignore-exports #-}

-- |
-- Effectful-native umbrella. Mirrors the shape of upstream 'Reflex.Dom'
-- (which is @Reflex.Dom.Core as X hiding (mainWidget...) + Reflex.Dom.Internal as X@)
-- but every re-export now points at the Effectful surface in
-- @reflex-dom-core-effectful@ via 'Reflex.Dom.Core'.
--
-- The umbrella hides the 'mainWidget'-family names that came from
-- 'Reflex.Dom.Core' so 'Reflex.Dom.Internal' can provide them
-- as the canonical origin at this package's namespace (matching the
-- upstream layering: @Internal@ owns the bootstrap wrappers).
module Reflex.Dom (module X) where

import Reflex.Effectful.DomHost as X hiding
  ( mainWidget, mainWidgetInElementById
  , mainWidgetWithCss, mainWidgetWithHead
  )
import Reflex.Dom.Internal as X
