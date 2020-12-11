----------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0238-Keyboard-Enhancements.md
----------------------------------------------------------------------------------------------------
-- Description: Check SDL is able to transfer 'OnKeyboardInput' notification from HMI to App
-- with new values for 'event'
--
-- Steps:
-- 1. App is registered
-- 2. HMI provides 'KeyboardCapabilities' within 'OnSystemCapabilityUpdated' notification
-- 3. App sends 'SetGlobalProperties' with 'maskInputCharacters=USER_CHOICE_INPUT_KEY_MASK'
-- 4. HMI sends 'OnKeyboardInput' notification with specific values for 'event':
--   - INPUT_KEY_MASK_ENABLED
--   - INPUT_KEY_MASK_DISABLED
-- SDL does:
--  - Transfer 'OnKeyboardInput' notification to App
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
    maskInputCharacters = "USER_CHOICE_INPUT_KEY_MASK"
  }
}

--[[ Local Functions ]]
local function ptUpd(pTbl)
  pTbl.policy_table.app_policies[common.getPolicyAppId()].groups = { "Base-4", "OnKeyboardInputOnlyGroup" }
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { ptUpd })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("HMI sends OnSCU", common.sendOnSCU)
runner.Step("App sends SetGP", common.sendSetGP, { sgpParams, common.result.success })
runner.Step("HMI sends OnKI", common.sendOnKI, { { data = "k", event = "INPUT_KEY_MASK_ENABLED" } })
runner.Step("HMI sends OnKI", common.sendOnKI, { { data = "k", event = "INPUT_KEY_MASK_DISABLED" } })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
