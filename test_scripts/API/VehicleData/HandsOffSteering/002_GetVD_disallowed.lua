---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL rejects GetVehicleDate request with resultCode: "DISALLOWED" if an app not allowed by
-- policy with new 'handsOffSteering' parameter
--
-- Preconditions:
-- 1) Update preloaded_pt file, add handsOffSteering parameter to VD_RPC group
-- 2) RPC GetVehicleData is Not allowed by policies
-- 3) App is registered
-- Steps:
-- 1) App sends valid GetVehicleData request to SDL
-- SDL does:
-- - a) send GetVehicleData response with (success = false, resultCode = DISALLOWED") to App
-- - b) not transfer this request to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')
local json = require("modules/json")

-- [[ Local Variable ]]
local VDGroup = {
  rpcs = {
    GetVehicleData = {
      hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
      parameters = json.EMPTY_ARRAY
    }
  }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.precondition)
common.Step("Update preloaded file", common.updatedPreloadedPTFile, { VDGroup })
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerAppWOPTU)

common.Title("Test")
common.Step("RPC GetVehicleData DISALLOWED", common.getVDDisallowed)

common.Title("Postconditions")
common.Step("Stop SDL", common.postcondition)
