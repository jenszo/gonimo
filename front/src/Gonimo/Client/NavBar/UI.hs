module Gonimo.Client.NavBar.UI where

import Control.Lens
import Reflex.Dom
import Gonimo.Client.NavBar.Internal
import Gonimo.Client.Reflex.Dom
import qualified Gonimo.Client.Family.Internal as Family
import qualified Gonimo.Client.DeviceList.Internal as DeviceList
import qualified Gonimo.Client.App.Types as App
import           Gonimo.Client.ConfirmationButton  (confirmationButton)


navBar :: forall m t. (HasWebView m, MonadWidget t m)
      => Config t -> m (NavBar t)
navBar config = do
    let loaded = config^.configLoaded
    let deviceList = config^.configDeviceList
    elClass "div" "navbar navbar-default" $ do
      elClass "div" "container" $ do
        backClicked' <- backButton
        homeClicked' <- homeButton
        elClass "div" "nav navbar-nav navbar-right" $ do
          elClass "p" "" $ do
            let deviceName = DeviceList.ownDeviceName (loaded^.App.authData) deviceList
            dynText deviceName
          elClass "p" "" $ do
            let cFamilyName = Family.currentFamilyName
                              $ Family.DefiniteFamily (loaded^.App.families) (loaded^.App.selectedFamily)
            dynText cFamilyName
        pure $ NavBar backClicked' homeClicked'
  where
    btnAttrs = "class" =: "btn btn-default navbar-btn"
    backInner = elClass "span" "glyphicon glyphicon-menu-left" blank
    homeInner = elClass "span" "glyphicon glyphicon-home" blank

    backButton = case config^.configConfirmationOnBack of
      NoConfirmation -> buttonAttr btnAttrs backInner
      WithConfirmation confText -> confirmationButton btnAttrs backInner confText

    homeButton = case config^.configConfirmationOnHome of
      NoConfirmation -> buttonAttr btnAttrs homeInner
      WithConfirmation confText -> confirmationButton btnAttrs homeInner confText

    
  -- where
    -- navLogo
    --   = elAttr "img" ( "alt" =: "gonimo"
    --                  <> "src" =: "pix/gonimo-brand-01.svg"
    --                  <> "height" =: "50px"
    --                  <> "style" =: "padding: 2px 3.5px 0px 3.5px;"
    --                  ) blank