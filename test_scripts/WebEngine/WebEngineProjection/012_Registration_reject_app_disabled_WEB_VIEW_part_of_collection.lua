---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0273-webengine-projection-mode.md
--
-- Description:
-- Check that non-webengine App will be rejected with HMI type collection {"MEDIA", "WEB_VIEW"} 
--
-- Precondition:
-- 1. SDL and HMI are started
-- 2. WebEngine device is connected to SDL
-- 3. PT contains record for App1 with enabled = false

-- Sequence:
-- 1. Set application properties with endpoint parameter
-- 2. Application1 try to register with WEB_VIEW appHMIType
--  a. SDL reject registration of application (resultCode DISALLOWED, success:"false")
---------------------------------------------------------------------------------------------------
-- [[ Required Shared Libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ Local Variables ]]
local appSessionId = 1
local appHMIType = {"MEDIA", "WEB_VIEW"}
local appProperties = {
  nicknames = { "Test Web Application_1", "Test Web Application_2" },
  policyAppID = "0000001",
  enabled = false,
  authToken = "ABCD12345",
  transportType = "WS",
  hybridAppPreference = "CLOUD",
}

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = appHMIType 
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 7
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 0

config.defaultMobileAdapterType = "WS"
common.testSettings.restrictions.sdlBuildOptions = {{ webSocketServerSupport = { "ON" }}}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Add AppHMIType to preloaded policy table", common.updatePreloadedPT,
  { appSessionId, appHMIType })
common.Step("Start SDL, HMI, connect Mobile", common.start)

common.Title("Test")
common.Step("SetAppProperties request for policyAppID", common.setAppProperties, { appProperties })
common.Step("Register App failed, application is not enabled", common.rejectedRegisterApp, {appSessionId})

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)


