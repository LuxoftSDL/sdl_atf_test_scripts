----------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0238-Keyboard-Enhancements.md
----------------------------------------------------------------------------------------------------
-- Description: Check SDL is unable to provide 'WindowCapabilities' to App
-- in case if HMI has sent 'OnSystemCapabilityUpdated' notification with invalid data
--
-- Steps:
-- 1. App is registered
-- 2. HMI provides 'KeyboardCapabilities' with invalid data within 'OnSystemCapabilityUpdated' notification
-- 3. App requests 'DISPLAYS' system capabilities through 'GetSystemCapability'
-- SDL does:
--  - Respond with DATA_NOT_AVAILABLE, success:false to App
----------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/KeyboardEnhancements/common')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local keyboardLayouts = { "QWERTY", "QWERTZ", "AZERTY", "NUMERIC" }

local tcs = {
  [01] = { maskInputCharactersSupported = "false" },
  [02] = { supportedKeyboardLayouts = { } },
  [03] = { supportedKeyboardLayouts = common.getArrayValue(keyboardLayouts, 1001) },
  [04] = { configurableKeys = { { keyboardLayout = "QWERTY", numConfigurableKeys = "0" }} },
  [05] = { configurableKeys = { { keyboardLayout = true, numConfigurableKeys = 0 }} },
  [06] = { configurableKeys = { { } } },
  [07] = { configurableKeys = { { keyboardLayout = "QWERTY", numConfigurableKeys = nil }} },
  [08] = { configurableKeys = { { keyboardLayout = nil, numConfigurableKeys = 0 }} },
  [09] = { configurableKeys = common.getArrayValue({ { keyboardLayout = "QWERTY", numConfigurableKeys = 0 }}, 1001) }
}

--[[ Local Functions ]]
local function getDispCaps(pTC)
  local dispCaps = common.getDispCaps()
  dispCaps.systemCapability.displayCapabilities[1].windowCapabilities[1].keyboardCapabilities = pTC
  return dispCaps
end

local function check(_, data)
  if data.payload.systemCapability ~= nil then
    return false, "Unexpected 'systemCapability' parameter received"
  end
  return true
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)

runner.Title("Test")
for tc, data in pairs(tcs) do
  runner.Title("TC[" .. string.format("%03d", tc) .. "]")
  local dispCaps = getDispCaps(data)
  runner.Step("HMI sends OnSCU", common.sendOnSCU, { dispCaps, common.expected.no })
  runner.Step("App sends GetSC", common.sendGetSC, { { }, common.result.data_not_available, check })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
