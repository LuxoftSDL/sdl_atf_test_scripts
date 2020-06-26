---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0273-webengine-projection-mode.md
--
-- Description:
-- Processing of the OnExitApplication notification from HMI
--
-- Precondition:
-- 1. SDL and HMI are started
-- 2. Web app is registered

-- Sequence:
-- 1. HMI sends BC.OnExitApplication with 'reason' = "RESOURCE_CONSTRAINT" to SDL
--  a. Web app is unregistered
--  b. Mobile session is disconnected
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local events = require("events")
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ Local Variables ]]
local appSessionId = 1
local appHMIType = "WEB_VIEW"

--[[ General test configuration ]]
config.application1.registerAppInterfaceParams.appHMIType = { appHMIType }
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 7
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 0

--[[ Local Functions ]]
local function onExitApp()
  local appID = common.getHMIAppId()
  local hmiConnection = common.getHMIConnection()
  local mobileSession = common.getMobileSession()
  hmiConnection:ExpectNotification("BasicCommunication.OnAppUnregistered",
      { unexpectedDisconnect = false, appID = appID })
  mobileSession:ExpectNotification("OnAppInterfaceUnregistered",
      { reason = "RESOURCE_CONSTRAINT" })
  mobileSession:ExpectEvent(events.disconnectedEvent, "Disconnected")
  hmiConnection:SendNotification("BasicCommunication.OnExitApplication",
      { reason = "RESOURCE_CONSTRAINT", appID = appID })
end

-- [[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Add AppHMIType to preloaded policy table", common.updatePreloadedPT,
  { appSessionId, { appHMIType }})
common.Step("Start SDL, HMI", common.startWOdeviceConnect)

common.Title("Test")
common.Step("Connect WebEngine device", common.connectWebEngine,
  { appSessionId, "WS" })
common.Step("Register App without PTU", common.registerAppWOPTU, { appSessionId })
common.Step("OnExitApplication", onExitApp)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
