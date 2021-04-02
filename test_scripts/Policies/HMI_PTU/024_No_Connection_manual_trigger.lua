---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0248-hmi-ptu-support.md
-- Issue:

-- Description: Check that PTU is successfully performed via HMI

-- In case:
-- 1. No app is connected
-- 2. And 'Manual' PTU trigger occurs
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
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } }

--[[ Local Functions ]]
local function manualPTU()
  local cid = common.hmi():SendRequest("SDL.UpdateSDL")
  common.hmi():ExpectResponse(cid, { result = { code = 0, method = "SDL.UpdateSDL", result = "UPDATE_NEEDED" }})
  common.hmi():ExpectRequest("BasicCommunication.PolicyUpdate")
  :Do(function(_, data)
      common.hmi():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  common.hmi():ExpectNotification("SDL.OnStatusUpdate", { status = "UPDATING" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI", common.startWithOutConnectMobile)

runner.Title("Test")
runner.Step("New HMI PTU on Manual trigger", manualPTU)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
