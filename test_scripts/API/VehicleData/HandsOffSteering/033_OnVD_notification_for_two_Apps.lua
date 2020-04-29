---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL processes OnVehicleData notification with new 'handsOffSteering' parameter for two Apps
--
-- Preconditions:
-- 1) Update preloaded_pt file, add handsOffSteering parameter to VD_RPC group
-- 2) OnVehicleData notification is allowed by policies
-- 3) App_1 is registered and subscribed on handsOffSteering parameter
-- Steps:
-- 1) HMI sends valid VehicleInfo.OnVehicleData notification to SDL
-- SDL does:
-- - a) transfer this notification to App_1
-- 4) App_2 is registered and subscribed on handsOffSteering parameter
-- Steps:
-- 2) HMI sends valid VehicleInfo.OnVehicleData notification to SDL
-- SDL does:
-- - a) transfer this notification to App_1 and App_2
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Variables ]]
local value = { true, false }
local rpc_sub = "SubscribeVehicleData"

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
common.Step("RPC " .. rpc_sub .. " on handsOffSteering parameter App_1", common.processRPCSuccess, { rpc_sub, 1 })

common.Title("Test")
for _, v in pairs(value) do
  common.Step("HMI sends OnVehicleData notification with handsOffSteering " .. tostring(v), common.onVehicleData, { v })
end
common.Step("Register App_2", common.registerAppWOPTU, { 2 })
common.Step("RPC " .. rpc_sub .. " on handsOffSteering parameter App_2", subscribeVehicleData, { rpc_sub, 2 })
for _, v in pairs(value) do
  common.Step("HMI sends OnVehicleData notification with handsOffSteering " .. tostring(v), onVehicleData, { v })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postcondition)
