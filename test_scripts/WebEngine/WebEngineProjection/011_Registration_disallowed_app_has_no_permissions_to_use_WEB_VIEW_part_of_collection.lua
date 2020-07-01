---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0273-webengine-projection-mode.md
--
-- Description:
-- Check that App will be disallowed to register with HMI type collection {"MEDIA", "NAVIGATION"} 
-- when application does not have permission to use WEB_VIEW hmi type in policy table
--
-- Precondition:
-- 1. SDL and HMI are started
-- 2. WebEngine device is connected to SDL
-- 3. PT contains record with for App1 with all properties for webengine app 
--    and appHMIType = MEDIA.

-- Sequence:
-- 1. Application1 try to register with WEB_VIEW appHMIType
--  a. SDL reject registration of application (resultCode: "DISALLOWED", success: false)
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultMobileAdapterType = "WS"

-- [[ Required Shared Libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ Local Variables ]]
local appSessionId = 1
local appHMITypeInPolicy = { "MEDIA", "NAVIGATION" }
local appHMIType = { "MEDIA", "NAVIGATION", "WEB_VIEW" }

local appsRAIParams = {
  appHMIType = appHMIType,
  syncMsgVersion = {
    majorVersion = 7,
    minorVersion = 0
  }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Setup RegisterAppInterface params", common.setupRAIParams, { appSessionId, appsRAIParams })
common.Step("Add AppHMIType to preloaded policy table", common.updatePreloadedPT,
  { appSessionId, appHMITypeInPolicy })
common.Step("Start SDL, HMI, connect Mobile", common.start)

common.Title("Test")
common.Step("Register App, PT does not contain WEB_VIEW AppHMIType", common.disallowedRegisterApp, { appSessionId })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)


