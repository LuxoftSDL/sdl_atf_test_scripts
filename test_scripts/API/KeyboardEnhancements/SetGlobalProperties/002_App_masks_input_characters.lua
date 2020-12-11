----------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0238-Keyboard-Enhancements.md
----------------------------------------------------------------------------------------------------
-- Description: Check App is able to mask input characters via 'maskInputCharacters' parameter
-- of `KeyboardProperties` struct
--
-- Steps:
-- 1. App is registered
-- 2. HMI provides 'KeyboardCapabilities' within 'OnSystemCapabilityUpdated' notification
-- 3. App sends 'SetGlobalProperties' with 'maskInputCharacters' in 'KeyboardProperties'
-- SDL does:
--  - Proceed with request successfully
----------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/KeyboardEnhancements/common')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local maskValues = { "ENABLE_INPUT_KEY_MASK", "DISABLE_INPUT_KEY_MASK", "USER_CHOICE_INPUT_KEY_MASK" }

--[[ Local Functions ]]
local function getSGPParams(pMaskValue)
  return {
    keyboardProperties = {
      keyboardLayout = "NUMERIC",
      maskInputCharacters = pMaskValue
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
for _, v in pairs(maskValues) do
  runner.Step("App sends SetGP " .. v, common.sendSetGP, { getSGPParams(v), common.result.success })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
