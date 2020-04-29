---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL restored SubscribeVehicleData on 'handsOffSteering' parameter after IGN_OFF/IGN_ON cycle
-- for two Apps
--
-- Preconditions:
-- 1) Update preloaded_pt file, add handsOffSteering parameter to VD_RPC group
-- 2) RPC SubscribeVehicleData is allowed by policies
-- 3) App_1 and App_2 are registered and subscribed on handsOffSteering VD
-- Steps:
-- 1) IGN_OFF/IGN_ON cycle is performed
-- 2) App_1 re-register with actual HashId
-- SDL does:
-- - a) send VehicleInfo.SubscribeVehicleData request to HMI during resumption
-- - b) process successful response from HMI
-- - c) respond RAI(SUCCESS) to mobile app
-- Steps:
-- 3) App_2 re-register with actual HashId
-- SDL does:
-- - a) not send VehicleInfo.SubscribeVehicleData request to HMI during resumption
-- - b) respond RAI(SUCCESS) to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Variable ]]
local rpc = "SubscribeVehicleData"

--[[ Local Functions ]]
local function subscribeVehicleData(pRpcName, pAppId)
  local handsOffSteeringResponseData = {
    dataType = "VEHICLEDATA_HANDSOFFSTEERING",
    resultCode = "SUCCESS"
  }
  local cid = common.getMobileSession(pAppId):SendRPC(pRpcName, { handsOffSteering = true })
  common.getMobileSession(pAppId):ExpectResponse(cid,
    { success = true, resultCode = "SUCCESS", handsOffSteering = handsOffSteeringResponseData })
    common.getMobileSession(pAppId):ExpectNotification("OnHashChange")
    :Do(function(_, data)
      common.setHashId(data.payload.hashID, pAppId)
    end)
end

local function checkResumptionDataApp1()
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

local function checkResumptionDataApp2()
  common.getHMIConnection():ExpectRequest("VehicleInfo." .. rpc):Times(0)
end

local function onVehicleData(pHandsOffSteering)
  common.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { handsOffSteering = pHandsOffSteering })
  common.getMobileSession(1):ExpectNotification("OnVehicleData", { handsOffSteering = pHandsOffSteering })
  common.getMobileSession(2):ExpectNotification("OnVehicleData", { handsOffSteering = pHandsOffSteering })
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.precondition)
common.Step("Update preloaded file", common.updatedPreloadedPTFile)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App_1", common.registerAppWOPTU, { 1 })
common.Step("RPC " .. rpc .. " on handsOffSteering parameter App_1", common.processRPCSuccess, { rpc, 1 })
common.Step("Register App_2", common.registerAppWOPTU, { 2 })
common.Step("RPC " .. rpc .. " on handsOffSteering parameter App_2", subscribeVehicleData, { rpc, 2 })

common.Title("Test")
common.Step("IGNITION_OFF", common.ignitionOff)
common.Step("IGNITION_ON", common.start)
common.Step("Re-register App_1 resumption data", common.reRegisterAppSuccess, { 1, checkResumptionDataApp1 })
common.Step("Check resumption data OnVehicleData notification", common.onVehicleData, { true })
common.Step("Re-register App_2 resumption data", common.reRegisterAppSuccess, { 2, checkResumptionDataApp2 })
common.Step("Check resumption data OnVehicleData notification for two Apps", onVehicleData, { true })

common.Title("Postconditions")
common.Step("Stop SDL", common.postcondition)
