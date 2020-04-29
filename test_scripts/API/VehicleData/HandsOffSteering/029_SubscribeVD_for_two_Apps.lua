---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL processes SubscribeVehicleData RPC for two Apps with new 'handsOffSteering' parameter
--
-- Preconditions:
-- 1) Update preloaded_pt file, add handsOffSteering parameter to VD_RPC group
-- 2) RPC SubscribeVehicleData is allowed by policies
-- 3) App_1 is registered
-- Steps:
-- 1) App_1 sends valid SubscribeVehicleData request to SDL
-- SDL does:
-- - a) transfer this request to HMI
-- Steps:
-- 2) HMI sends all VehicleInfo.SubscribeVehicleData response to SDL
-- SDL does:
-- - a) respond SUCCESS, success:true and parameter value received from HMI to App_1
-- - b) send OnHashChange notification to App_1
-- 4) App_2 is registered
-- Steps:
-- 3) App_2 sends valid SubscribeVehicleData request to SDL
-- SDL does:
-- - a) respond SUCCESS, success:true and parameter value received from HMI to mobile application
-- - b) send OnHashChange notification to App_2
-- - c) not transfer this request to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Variable ]]
local rpc_sub = "SubscribeVehicleData"

--[[ Local Function ]]
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

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.precondition)
common.Step("Update preloaded file", common.updatedPreloadedPTFile)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App_1", common.registerAppWOPTU, { 1 })
common.Step("RPC " .. rpc_sub .. " on handsOffSteering parameter for App_1", common.processRPCSuccess, { rpc_sub, 1 })

common.Title("Test")
common.Step("Register App_2", common.registerAppWOPTU, { 2 })
common.Step("RPC " .. rpc_sub .. " on handsOffSteering parameter for App_2", subscribeVehicleData, { rpc_sub, 2 })

common.Title("Postconditions")
common.Step("Stop SDL", common.postcondition)
