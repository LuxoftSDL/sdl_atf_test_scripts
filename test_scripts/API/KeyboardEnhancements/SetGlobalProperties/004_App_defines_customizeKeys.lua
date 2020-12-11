----------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0238-Keyboard-Enhancements.md
----------------------------------------------------------------------------------------------------
-- Description: Check App is able to change special characters via 'customizeKeys' parameter
-- of 'KeyboardProperties' struct
--
-- Steps:
-- 1. App is registered
-- 2. HMI provides 'KeyboardCapabilities' within 'OnSystemCapabilityUpdated' notification
-- 3. App sends 'SetGlobalProperties' with 'customizeKeys' in 'KeyboardProperties'
-- SDL does:
--  - Proceed with request successfully
----------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/KeyboardEnhancements/common')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local keys = { "$", "#", "&" }

--[[ Local Functions ]]
local function getSGPParams(pKey)
  return {
    keyboardProperties = {
      keyboardLayout = "NUMERIC",
      customizeKeys = { pKey }
    }
  }
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)

runner.Title("Test")
runner.Step("HMI sends OnSCU", common.sendOnSCU)
for _, v in pairs(keys) do
  runner.Step("App sends SetGP", common.sendSetGP, { getSGPParams(v), common.result.success })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
