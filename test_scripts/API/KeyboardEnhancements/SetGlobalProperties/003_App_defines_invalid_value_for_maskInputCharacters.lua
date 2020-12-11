----------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0238-Keyboard-Enhancements.md
----------------------------------------------------------------------------------------------------
-- Description: Check App receives 'INVALID_DATA' in case it defines invalid value for 'maskInputCharacters'
-- parameter of 'KeyboardProperties' struct
--
-- Steps:
-- 1. App is registered
-- 2. HMI provides 'KeyboardCapabilities' within 'OnSystemCapabilityUpdated' notification
-- 3. App sends 'SetGlobalProperties' with invalid value for 'maskInputCharacters' parameter in 'KeyboardProperties'
-- SDL does:
--  - Not transfer request to HMI
--  - Respond with INVALID_DATA, success:false to App
----------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/KeyboardEnhancements/common')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local sgpParams = {
  keyboardProperties = {
    keyboardLayout = "NUMERIC",
    maskInputCharacters = true --invalid type
  }
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)

runner.Title("Test")
runner.Step("HMI sends OnSCU", common.sendOnSCU)
runner.Step("App sends SetGP", common.sendSetGP, { sgpParams, common.result.invalid_data })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
