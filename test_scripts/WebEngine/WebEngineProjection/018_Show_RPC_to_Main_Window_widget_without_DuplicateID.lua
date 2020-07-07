---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0273-webengine-projection-mode.md
--
-- Description: Processing of RPCs for widgets which does not duplicate main window
-- "duplicateUpdatesFromWindowID" param is not defined) when application has active WEB_VIEW template
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) WebEngine App with WEB_VIEW HMI type is registered
-- 3) App successfully created a widget which does not duplicate main window
-- 4) Widget is activated on the HMI and has FULL level
-- Steps:
-- 1) App sends Show(with WindowID for Main window) request to SDL
-- SDL does:
--  - send request UI.Show(without WindowID) to HMI
-- 2) HMI sends UI.Show response "SUCCESS"
-- SDL does:
--  - send Show response with (success: true resultCode: "SUCCESS") to App
--  - not send OnSystemCapabilityUpdated notification to App
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

local createWindowParams = {
  windowID = 1,
  windowName = "Name",
  type = "WIDGET"
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
common.Step("App sends CreateWindow RPC", common.createWindow, { createWindowParams })
common.Step("Widget is activated", common.activateWidgetFromNoneToFULL, { createWindowParams.windowID, 1 })

common.Title("Test")
common.Step("Success Show RPC to Main window", common.sendShowToWindow, { 0 })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
