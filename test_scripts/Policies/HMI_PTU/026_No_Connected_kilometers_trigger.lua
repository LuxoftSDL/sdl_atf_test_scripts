---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0248-hmi-ptu-support.md
-- Issue:

-- Description: Check that PTU is successfully performed via HMI

-- In case:
-- 1. No app is connected
-- 2. And 'Exchange after X kilometers' PTU trigger occurs
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
local odometer = 500

--[[ Local Functions ]]
local function updatePreloadedKilometers(pTbl)
  pTbl.policy_table.module_config.exchange_after_x_kilometers = odometer
end

local function noPTUTriggerOnOdometer()
  common.hmi():SendNotification("VehicleInfo.OnVehicleData", { odometer = odometer - 1 })
  common.hmi():ExpectRequest("BasicCommunication.PolicyUpdate")
  :Times(0)
  common.hmi():ExpectNotification("SDL.OnStatusUpdate")
  :Times(0)
end

local function newPTUTriggerOnOdometer()
  common.hmi():SendNotification("VehicleInfo.OnVehicleData", { odometer = odometer })
  common.hmi():ExpectRequest("BasicCommunication.PolicyUpdate")
  :Do(function(_, data)
      common.hmi():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  common.hmi():ExpectNotification("SDL.OnStatusUpdate", { status = "UPDATE_NEEDED" }, { status = "UPDATING" })
  :Times(2)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Preloaded update", common.updatePreloaded, { updatePreloadedKilometers })
runner.Step("Start SDL, HMI", common.startWithOutConnectMobile)

runner.Title("Test")
runner.Step("No HMI PTU on Odometer trigger", noPTUTriggerOnOdometer)
runner.Step("New HMI PTU on Odometer trigger", newPTUTriggerOnOdometer)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
