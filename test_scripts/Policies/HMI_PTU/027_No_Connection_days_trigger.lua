---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0248-hmi-ptu-support.md
-- Issue:

-- Description: Check that PTU is successfully performed via HMI without mobile connection

-- In case:
-- 1. No app is connected
-- 2. And 'Exchange after X days' PTU trigger occurs
-- SDL does:
--   a) Start new PTU sequence through HMI:
--      - Send 'BC.PolicyUpdate' request to HMI
--      - Send 'SDL.OnStatusUpdate(UPDATE_NEEDED)' notification to HMI
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Policies/HMI_PTU/common_hmi_ptu')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "PROPRIETARY", "EXTERNAL_PROPRIETARY" } } }

--[[ Local Variables ]]
local days = 30

--[[ Local Functions ]]
local function updatePreloadedDays(pTbl)
  pTbl.policy_table.module_config.exchange_after_x_days = days
end

local function ignitionOnNoPTU()
  common.startWithOutConnectMobile()
  common.hmi():ExpectRequest("BasicCommunication.PolicyUpdate")
  :Times(0)
  common.hmi():ExpectNotification("SDL.OnStatusUpdate")
  :Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Preloaded update", common.updatePreloaded, { updatePreloadedDays })
runner.Step("Clear HMICapabilitiesCacheFile parameter in INI file",
  common.setSDLIniParameter, {"HMICapabilitiesCacheFile", ""})
runner.Step("Ignition On without PTU, Start SDL, HMI", ignitionOnNoPTU)

runner.Title("Test")
runner.Step("Ignition Off", common.ignitionOff)
runner.Step("Ignition On without PTU", ignitionOnNoPTU)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
