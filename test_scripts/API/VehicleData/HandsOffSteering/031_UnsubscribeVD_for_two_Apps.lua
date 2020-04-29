---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL processes UnsubscribeVehicleData RPC for two Apps with new 'handsOffSteering' parameter
--
-- Preconditions:
-- 1) Update preloaded_pt file, add handsOffSteering parameter to VD_RPC group
-- 2) RPC UnsubscribeVehicleData is allowed by policies
-- 3) App_1 and App_2 are registered and Subscribed on handsOffSteering parameter
-- Steps:
-- 1) App_1 sends valid UnsubscribeVehicleData request to SDL
-- SDL does:
-- - a) send UnsubscribeVehicleData response with (success = true, resultCode = SUCCESS") to App_1
-- - b) send OnHashChange notification to App_1
-- - c) not transfer this request to HMI
-- Steps:
-- 2) App_2 sends valid UnsubscribeVehicleData request to SDL
-- SDL does:
-- - a) transfer this request to HMI
-- Steps:
-- 3) HMI sends all VehicleInfo.UnsubscribeVehicleData response to SDL
-- SDL does:
-- - a) respond SUCCESS, success:true and parameter value received from HMI to App_2
-- - b) send OnHashChange notification to App_2
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Variables ]]
local rpc_sub = "SubscribeVehicleData"
local rpc_unsub = "UnsubscribeVehicleData"

--[[ Local Function ]]
local function processRPCSuccess(pRpcName, pAppId)
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
common.Step("Register App_2", common.registerAppWOPTU, { 2 })
common.Step("RPC " .. rpc_sub .. " on handsOffSteering parameter for App_2", processRPCSuccess, { rpc_sub, 2 })

common.Title("Test")
common.Step("RPC " .. rpc_unsub .. " on handsOffSteering parameter for App_1", processRPCSuccess, { rpc_unsub, 1 })
common.Step("RPC " .. rpc_unsub .. " on handsOffSteering parameter for App_2",
  common.processRPCSuccess, { rpc_unsub, 2 })

common.Title("Postconditions")
common.Step("Stop SDL", common.postcondition)
