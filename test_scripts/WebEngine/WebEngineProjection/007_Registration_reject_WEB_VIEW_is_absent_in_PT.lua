---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0273-webengine-projection-mode.md
--
-- Description:
-- Check that App will be rejected with HMI type WEB_VIEW 
-- when WEB_VIEW AppHmiType is absent in application policies
--
-- Precondition:
-- 1. SDL and HMI are started
-- 2. WebEngine device is connected to SDL

-- Sequence:
-- 1. Application1 try to register with WEB_VIEW appHMIType
--  a. SDL reject registration of application (resultCode REJECT, success:"false")
---------------------------------------------------------------------------------------------------
-- [[ Required Shared Libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ Local Variables ]]
local appSessionId = 1
local appHMITypeWebView = "WEB_VIEW"
local appHMITypeMedia = "MEDIA"

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = { appHMITypeWebView }
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 7
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 0

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Add AppHMIType to preloaded policy table", common.updatePreloadedPT,
  { appSessionId, { appHMITypeMedia }})
common.Step("Start SDL, HMI, connect Mobile", common.start)

common.Title("Test")
common.Step("Register App, PT does not contain WEB_VIEW AppHMIType", common.rejectedRegisterApp)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)

