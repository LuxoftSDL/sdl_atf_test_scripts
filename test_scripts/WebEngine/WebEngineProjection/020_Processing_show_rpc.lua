---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0273-webengine-projection-mode.md
--
-- Description: Processing of Show rpc when application has active WEB_VIEW template
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) WebEngine App with WEB_VIEW HMI type is registered
-- Steps:
-- 1) App sends `Show` request without `templateConfiguration` for main window (windowID is not defined)
-- SDL does:
--  - proceed with `Show` request successfully
--  - not send `OnSystemCapabilityUpdated` to App
---------------------------------------------------------------------------------------------------
--[[ General test configuration ]]
config.defaultMobileAdapterType = "WS"

--[[ Required Shared libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ Local Variables ]]
local appSessionId = 1
local appHMIType = { "WEB_VIEW" }
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
common.Step("Setup RegisterAppInterface params for App1", common.setupRAIParams, { appSessionId, appsRAIParams })
common.Step("Update WS Server Certificate parameters in smartDeviceLink.ini file", common.commentAllCertInIniFile)
common.Step("Add AppHMIType to preloaded policy table", common.updatePreloadedPT, { appSessionId, appHMIType })
common.Step("Start SDL, HMI, connect WebEngine device", common.start)
common.Step("Register App without PTU", common.registerAppWOPTU, { appSessionId })
common.Step("Activate web app", common.activateApp, { appSessionId })

common.Title("Test")
common.Step("Success Show RPC to Main window", common.sendShowToWindow, { nil })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
