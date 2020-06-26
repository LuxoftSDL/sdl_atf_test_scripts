---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0273-webengine-projection-mode.md
--
-- Description:
-- Check that App will be rejected with HMI type WEB_VIEW 
-- when WEB_VIEW AppHmiType is part of HMI types collection and absent in application policies
--
-- Precondition:
-- 1. SDL and HMI are started
-- 2. WebEngine device is connected to SDL
-- 3. PT contains record for App1 and no record for App2

-- Sequence:
-- 1. Application1 registers with WEB_VIEW appHMIType successfully
-- 2. Application2 registers with WEB_VIEW appHMIType successfully
--  a. SDL rejects registration of application (resultCode DISALLOWED, success:"false")
---------------------------------------------------------------------------------------------------
-- [[ Required Shared Libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ Local Variables ]]
local appSessionId = 1
local appNotInPTSessionId = 2
local appHMIType = {"MEDIA", "WEB_VIEW"}

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = appHMIType 
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 7
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 0

config.application2.registerAppInterfaceParams.appHMIType = appHMIType 
config.application2.registerAppInterfaceParams.syncMsgVersion.majorVersion = 7
config.application2.registerAppInterfaceParams.syncMsgVersion.minorVersion = 0

config.defaultMobileAdapterType = "WS"
common.testSettings.restrictions.sdlBuildOptions = {{ webSocketServerSupport = { "ON" }}}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Add AppHMIType to preloaded policy table", common.updatePreloadedPT,
  { appSessionId, appHMIType })
common.Step("Start SDL, HMI, connect Mobile", common.start)

common.Title("Test")
common.Step("Register App 1, PT contains record for App1", common.registerAppWOPTU, {appSessionId})
common.Step("Register App 2, PT does not contain record for App2", common.rejectedRegisterApp, {appNotInPTSessionId})

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)


