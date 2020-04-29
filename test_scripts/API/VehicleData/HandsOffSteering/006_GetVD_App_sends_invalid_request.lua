---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL receive INVALID_DATA to GetVehicleDate request if App send is invalid data
--
-- Preconditions:
-- 1) Update preloaded_pt file, add handsOffSteering parameter to VD_RPC group
-- 2) RPC GetVehicleData is allowed by policies
-- 3) App is registered
-- Steps:
-- 1) App sends invalid GetVehicleData request to SDL
-- SDL does:
-- - a) send GetVehicleData response with (success = false, resultCode = INVALID_DATA") to App
-- - b) not transfer this request to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Function ]]
local function getVDInvalidRequest()
  local cid = common.getMobileSession():SendRPC("GetVehicleData", { handsOffSteering = 123 }) -- invalid data
  common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData") :Times(0)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA" })
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.precondition)
common.Step("Update preloaded file", common.updatedPreloadedPTFile)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerAppWOPTU)

common.Title("Test")
common.Step("RPC GetVehicleData, App with invalid request", getVDInvalidRequest)

common.Title("Postconditions")
common.Step("Stop SDL", common.postcondition)
