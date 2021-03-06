{-# LANGUAGE GADTs #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE FlexibleInstances #-}
module Gonimo.Client.Storage.Keys where

import Data.Text (Text)
import Gonimo.SocketAPI.Types as API
import Data.Aeson (FromJSON, ToJSON, toEncoding, genericToEncoding, defaultOptions)
import Gonimo.SocketAPI.Types (FamilyId)
import GHC.Generics (Generic)
import Gonimo.I18N (Locale(..))

data Key a = KeyAuthData
           | CurrentFamily
           | CameraEnabled
           | SelectedCamera
           | LastBabyName
           | AutoStart
           | HideBrowserWarning
           | UserLocale

deriving instance Generic (Key a)

-- | Needed because deriving clause did not work for GADT, although it should according to documentation
keyAuthData :: Key API.AuthData
keyAuthData = KeyAuthData

currentFamily :: Key FamilyId
currentFamily = CurrentFamily

selectedCamera :: Key Text
selectedCamera = SelectedCamera

cameraEnabled :: Key Bool
cameraEnabled = CameraEnabled

lastBabyName :: Key Text
lastBabyName = LastBabyName

autoStart :: Key Bool
autoStart = AutoStart

userLocale :: Key Locale
userLocale = UserLocale

hideBrowserWarning :: Key Bool
hideBrowserWarning = HideBrowserWarning

instance FromJSON (Key a)
instance ToJSON (Key a) where
  toEncoding = genericToEncoding defaultOptions



-- currentFamily :: Key (Gonimo.Key Family)
-- currentFamily = CurrentFamily

-- videoEnabled :: Key Boolean
-- videoEnabled = VideoEnabled
