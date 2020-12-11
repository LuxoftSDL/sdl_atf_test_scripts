----------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0238-Keyboard-Enhancements.md
----------------------------------------------------------------------------------------------------
-- Description: Check SDL correctly proceed with 'SetGlobalProperties' requests
-- with 'KeyboardProperties' parameters for multiple apps
--
-- Steps:
-- 1. App_1 and App_2 are registered
-- 2. HMI provides two different sets of 'KeyboardCapabilities' within 'OnSystemCapabilityUpdated' notifications
-- to App_1 and to App_2
-- 3. App_1 sends 'SetGlobalProperties' with 'KeyboardProperties' which are corresponds to App_1
-- SDL does:
--  - Proceed with request successfully
-- 4. App_1 sends 'SetGlobalProperties' with 'KeyboardProperties' which are corresponds to App_2
-- SDL does:
--  - Not proceed with request and respond with INVALID_DATA, success:false to App
-- 5. App_2 sends 'SetGlobalProperties' with 'KeyboardProperties' which are corresponds to App_2
-- SDL does:
--  - Proceed with request successfully
-- 6. App_2 sends 'SetGlobalProperties' with 'KeyboardProperties' which are corresponds to App_1
-- SDL does:
--  - Not proceed with request and respond with INVALID_DATA, success:false to App
----------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/KeyboardEnhancements/common')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local dispCaps1 = common.getDispCaps()
dispCaps1.systemCapability.displayCapabilities[1].windowCapabilities[1].keyboardCapabilities = {
  maskInputCharactersSupported = true,
  supportedKeyboardLayouts = { "AZERTY" },
  configurableKeys = { { keyboardLayout = "AZERTY", numConfigurableKeys = 2 } }
}
local dispCaps2 = common.getDispCaps()
dispCaps2.systemCapability.displayCapabilities[1].windowCapabilities[1].keyboardCapabilities = {
  maskInputCharactersSupported = false,
  supportedKeyboardLayouts = { "NUMERIC" },
  configurableKeys = { { keyboardLayout = "NUMERIC", numConfigurableKeys = 1 } }
}

--[[ Local Functions ]]
local function getSGPParams(pLayout, pNumOfKeys)
  local keys = { "$", "#", "&" }
  return {
    keyboardProperties = {
      keyboardLayout = pLayout,
      customizeKeys = common.getArrayValue(keys, pNumOfKeys)
    }
  }
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerAppWOPTU, { 1 })
runner.Step("Register App", common.registerAppWOPTU, { 2 })

runner.Title("Test")
runner.Step("HMI sends OnSCU for App 1", common.sendOnSCU, { dispCaps1, nil, nil, 1 })
runner.Step("HMI sends OnSCU for App 2", common.sendOnSCU, { dispCaps2, nil, nil, 2 })

runner.Title("App 1")
runner.Step("App 1 sends SetGP valid", common.sendSetGP,
  { getSGPParams("AZERTY", 1), common.result.success, nil, 1 })
runner.Step("App 1 sends SetGP valid", common.sendSetGP,
  { getSGPParams("AZERTY", 2), common.result.success, nil, 1 })
runner.Step("App 1 sends SetGP invalid", common.sendSetGP,
  { getSGPParams("AZERTY", 3), common.result.invalid_data, nil, 1 })
runner.Step("App 1 sends SetGP invalid", common.sendSetGP,
  { getSGPParams("NUMERIC", 1), common.result.invalid_data, nil, 1 })

runner.Title("App 2")
runner.Step("App 2 sends SetGP valid", common.sendSetGP,
  { getSGPParams("NUMERIC", 1), common.result.success, nil, 2 })
runner.Step("App 2 sends SetGP invalid", common.sendSetGP,
  { getSGPParams("NUMERIC", 2), common.result.invalid_data, nil, 2 })
runner.Step("App 2 sends SetGP invalid", common.sendSetGP,
  { getSGPParams("AZERTY", 1), common.result.invalid_data, nil, 2 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
