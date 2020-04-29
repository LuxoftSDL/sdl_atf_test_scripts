---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL restored SubscribeVehicleData on 'handsOffSteering' parameter after IGN_OFF/IGN_ON cycle
--
-- Preconditions:
-- 1) Update preloaded_pt file, add handsOffSteering parameter to VD_RPC group
-- 2) RPC SubscribeVehicleData is allowed by policies
-- 3) App is registered and subscribed on handsOffSteering VD
-- Steps:
-- 1) IGN_OFF/IGN_ON cycle is performed
-- 2) App re-register with actual HashId
-- SDL does:
-- - a) send VehicleInfo.SubscribeVehicleData request to HMI during resumption
-- - b) process successful response from HMI
-- - c) respond RAI(SUCCESS) to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Variable ]]
local rpc = "SubscribeVehicleData"

--[[ Local Function ]]
local function checkResumptionData()
  local handsOffSteeringResponseData = {
    dataType = "VEHICLEDATA_HANDSOFFSTEERING",
    resultCode = "SUCCESS"
  }
  common.getHMIConnection():ExpectRequest("VehicleInfo." .. rpc, { handsOffSteering = true })
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
      { handsOffSteering = handsOffSteeringResponseData })
  end)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.precondition)
common.Step("Update preloaded file", common.updatedPreloadedPTFile)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerAppWOPTU)
common.Step("RPC " .. rpc .. " on handsOffSteering parameter", common.processRPCSuccess, { rpc })

common.Title("Test")
common.Step("IGNITION_OFF", common.ignitionOff)
common.Step("IGNITION_ON", common.start)
common.Step("Re-register App resumption data", common.reRegisterAppSuccess, { 1, checkResumptionData })
common.Step("Check resumption data OnVehicleData notification", common.onVehicleData, { true })

common.Title("Postconditions")
common.Step("Stop SDL", common.postcondition)
