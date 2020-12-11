----------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0238-Keyboard-Enhancements.md
----------------------------------------------------------------------------------------------------
-- Description: Check SDL is unable to provide 'WindowCapabilities' to App
-- in case if HMI has not sent 'OnSystemCapabilityUpdated' notification
--
-- Steps:
-- 1. App is registered
-- 2. HMI doesn't send 'OnSystemCapabilityUpdated' notification with 'WindowCapabilities'
-- 3. App requests 'DISPLAYS' system capabilities through 'GetSystemCapability'
-- SDL does:
--  - Respond with DATA_NOT_AVAILABLE, success:false to App
----------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/KeyboardEnhancements/common')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
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
runner.Step("App sends GetSC", common.sendGetSC, { { }, common.result.data_not_available, check })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
