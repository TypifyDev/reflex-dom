{-# LANGUAGE CPP #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE TypeOperators #-}

#if defined(ANDROID)
module Reflex.Dom.Location.Platform where

import Effectful (Eff, (:>))
import Reflex.Class (Event, Reflex)
import Reflex.Class (PerformEvent, performEvent_)
import Reflex.Effectful.DomHost (goBack, withGlobalJSExecutor)

-- | Pop the browser history one step per occurrence of the supplied
-- event. Android implementation: routes through the global 'JSExecutor'
-- installed by 'Reflex.Dom.Core'
-- so the WebView's native back-stack is used (matches upstream MTL).
--
-- Effect row: 'PerformEvent' schedules the per-occurrence FFI call.
-- 'Reflex t' is required for the 'Functor' instance on 'Event t' that
-- the '<$' below relies on. No 'JSM'' / 'IOE' constraints — the FFI
-- call is raw 'IO' inside 'EventME'.
popHistoryState
  :: forall t es
   . ( Reflex t
     , PerformEvent t :> es
     )
  => Event t ()
  -> Eff es ()
popHistoryState evt =
  performEvent_ ((withGlobalJSExecutor goBack) <$ evt)
#else
-- Non-Android platforms have no per-platform 'popHistoryState' in the
-- Effectful port yet. Downstream consumers wanting popHistoryState on
-- non-Android should route through their own effect handler. This
-- module compiles empty on non-Android so the umbrella package stays
-- buildable across platform CPP branches.
module Reflex.Dom.Location.Platform () where

#endif
