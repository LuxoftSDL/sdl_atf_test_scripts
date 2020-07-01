---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0273-webengine-projection-mode.md
--
-- Description:
-- Processing of the OnExitApplication notification with reason RESOURCE_CONSTRAINT from HMI
--  (multiple applications on one connection)
--
-- Precondition:
-- 1. SDL and HMI are started
-- 2. App1 and App2 are registered on one mobile connection
--
-- Steps:
-- 1. HMI sends BC.OnExitApplication with reason: "RESOURCE_CONSTRAINT" related to App2 to SDL
-- SDL does:
--  - unregister App2 and send OnAppInterfaceUnregistered notification with reason: "RESOURCE_CONSTRAINT" to it
--  - send BasicCommunication.OnAppUnregistered notification related to App2 with unexpectedDisconnect: false
--  - does not close mobile connection
--  - does not send send OnAppInterfaceUnregistered notification with reason: "RESOURCE_CONSTRAINT" to App1
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ Local Variables ]]
local appId1 = 1
local appId2 = 2

-- [[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect mobile", common.start)
common.Step("Register App1 without PTU", common.registerAppWOPTU, { appId1 })
common.Step("Register App2 without PTU", common.registerAppWOPTU, { appId2 })

common.Title("Test")
common.Step("App2 receives OnExitApplication", common.processResourceConstraintExit, { appId2 })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
