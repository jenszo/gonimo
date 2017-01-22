{-# LANGUAGE RecursiveDo #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE GADTs #-}
module Gonimo.Client.Family.UI where

import Reflex.Dom
import Control.Monad
import Data.Monoid
import Data.Text (Text)
import Gonimo.Db.Entities (FamilyId)
import qualified Gonimo.Db.Entities as Db
import Data.Map (Map)
import qualified Data.Map as Map
import qualified Data.Set as Set
import Data.Set (Set)
import qualified Gonimo.SocketAPI.Types as API
import qualified Gonimo.SocketAPI as API
import Control.Lens
import qualified GHCJS.DOM.JSFFI.Generated.Window as Window
import qualified Gonimo.Client.Storage as GStorage
import qualified Gonimo.Client.Storage.Keys as GStorage
import qualified GHCJS.DOM as DOM
import Data.Foldable (traverse_)
import Gonimo.Client.Reflex
import Data.Maybe (fromMaybe)
import qualified Gonimo.Types as Gonimo
import qualified Gonimo.Client.Invite as Invite
import Control.Monad.IO.Class (liftIO)
import Unsafe.Coerce
import Debug.Trace (trace)

import Gonimo.Client.Family.Internal

-- Overrides configCreateFamily && configLeaveFamily
ui :: forall m t. (HasWebView m, MonadWidget t m)
            => Config t -> m (Family t)
ui config = mdo
    family' <- family $ config & configCreateFamily .~ clickedAdd
                               & configLeaveFamily .~ clickedLeave
                               & configSelectFamily .~ leftmost [famSelectedEv, config^.configSelectFamily]

    famSelectedEv <- familyChooser family'
    -- let famSelectedEv = never
    clickedAdd <- button "+"
    clickedLeave <- button "Leave"

    invResult <- fromMaybeDyn ("inv: " <>) invalidContents (validContents config) $ family'^.selectedFamily
    invReqs <- switchPromptly never invResult
    -- let invReqs = never

    pure $ family' & request %~ (<> invReqs)


familyChooser :: forall m t. (HasWebView m, MonadWidget t m)
                 => Family t -> m (Event t FamilyId)
familyChooser family' = do
  evFamilies <- waitForJust (family'^.families)

  let onFamilies families' =
        fromMaybeDyn ("select: " <>)
          (do
              el "div" $ text "Create a family to get started (+)"
              pure never
          )
          (\selected ->
              familyChooser' (DefiniteFamily families' selected)
          )
          (family'^.selectedFamily)
  let noFamilies = do
        el "div" $ text "Loading your families ..."
        pure never
  dynEvEv <- widgetHold noFamilies (onFamilies <$> evFamilies)
  let evEv = switchPromptlyDyn dynEvEv -- Flatten Dynamic Event Event
  traceEvent "Family Chooser In Action" <$> switchPromptly never evEv


familyChooser' :: forall m t. (HasWebView m, MonadWidget t m)
                 => DefiniteFamily t -> m (Event t FamilyId)
familyChooser' family' = do
  elAttr "div" ( "class" =: "dropdown" <> "data-toggle" =: "collapse" ) $ do
    elAttr "button" ( "class" =: "dropdown-toggle btn btn-primary" <> "href" =: "#"
                <> "role" =: "button" <> "data-toggle" =: "dropdown"
                <> "type" =: "button") $ do
      elClass "i" "fa fa-fw fa-users" blank
      text " "
      dynText $ zipDynWith getFamilyName (family'^.definiteSelected) (family'^.definiteFamilies)
      text " "
      elClass "span" "caret" blank
    selectedId <- elClass "ul" "dropdown-menu" $ do
      elAttr "li" ("data-toggle" =: "collapse") $
        elAttr "div" ("class" =: "dropdown-header") $
        text "Switch to family:"
      renderFamilySelectors family'
    pure selectedId
  where
    getFamilyName :: FamilyId -> Map FamilyId Db.Family -> Text
    getFamilyName famId families'
      = fromMaybe "" $ families'^?at famId._Just.to (Gonimo.familyName . Db.familyName)

renderFamilySelectors :: forall m t. (HasWebView m, MonadWidget t m)
                    => DefiniteFamily t -> m (Event t FamilyId)
renderFamilySelectors family' = fmap fst <$> selectViewListWithKey (family'^.definiteSelected) (family'^.definiteFamilies) renderFamilySelector

-- Internal helper for familyChooser ...
renderFamilySelector :: forall m t. (HasWebView m, MonadWidget t m)
                    => FamilyId -> Dynamic t Db.Family -> Dynamic t Bool -> m (Event t ())
renderFamilySelector _ family' selected' = do
    elAttr "li" ("data-toggle" =: "collapse") $ do
      fmap (domEvent Click . fst) . elAttr' "a" ("type" =: "button" <> "role" =: "button")
        $ dynText
          $ (Gonimo.familyName . Db.familyName <$> family') <> ffor selected' (\selected -> if selected then " ✔" else "")

invalidContents ::forall m t a. (HasWebView m, MonadWidget t m)
            => m (Event t a)
invalidContents = do
  el "div" $ text "Please create a family to get started ..."
  pure never

validContents ::forall m t. (HasWebView m, MonadWidget t m)
            => Config t -> Dynamic t FamilyId -> m (Event t [API.ServerRequest])
validContents config selected = do
    invite <- Invite.ui $ Invite.Config { Invite._configResponse = config^.configResponse
                                        , Invite._configSelectedFamily = selected
                                        , Invite._configCreateInvitation = never
                                        , Invite._configAuthenticated = config^.configAuthenticated
                                        }
    pure $ invite^.Invite.request