---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL processes GetVD, SubscribeVD, UnsubscribeVD, OnVD RPCs with new 'handsOffSteering'
-- parameter if an app registered with version large than 6.2 version
--
-- Preconditions:
-- 1) Update preloaded_pt file, add handsOffSteering parameter to VD_RPC group
-- 2) RPC is allowed by policies
-- 3) App is registered with syncMsgVersion = 6.3
-- Steps:
-- 1) App sends valid GetVehicleData request to SDL
-- SDL does:
-- - a) transfer this request to HMI
-- Steps:
-- 2) HMI sends all VehicleInfo.GetVehicleData response to SDL
-- SDL does:
-- - a) send GetVehicleData response with (success = true, resultCode = SUCCESS") to App
-- Steps:
-- 3) App send valid SubscribeVehicleData request to SDL
-- SDL does:
-- - a) transfer this request to HMI
-- Steps:
-- 4) HMI sends all VehicleInfo.SubscribeVehicleData response to SDL
-- SDL does:
-- - a) send SubscribeVehicleData response with (success = true, resultCode = SUCCESS") to App
-- - b) send OnHashChange notification to App
-- Steps:
-- 5) HMI sends valid VehicleInfo.OnVehicleData notification to SDL
-- SDL does:
-- - a) transfer this notification to App
-- Steps:
-- 6) App sends valid UnsubscribeVehicleData request to SDL
-- SDL does:
-- - a) transfer this request to HMI
-- Steps:
-- 7) HMI sends all VehicleInfo.UnsubscribeVehicleData response to SDL
-- SDL does:
-- - a) send UnsubscribeVehicleData response with (success = true, resultCode = SUCCESS") to App
-- - b) send OnHashChange notification to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Test Configuration ]]
common.getParams().syncMsgVersion.majorVersion = 7
common.getParams().syncMsgVersion.minorVersion = 3

--[[ Local Variables ]]
local rpc_sub = "SubscribeVehicleData"
local rpc_unsub = "UnsubscribeVehicleData"

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.precondition)
common.Step("Update preloaded file", common.updatedPreloadedPTFile)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerAppWOPTU)

common.Title("Test")
common.Step("RPC GetVehicleData, handsOffSteering", common.getVehicleData, { true })
common.Step("RPC " .. rpc_sub .. " on handsOffSteering parameter", common.processRPCSuccess, { rpc_sub })
common.Step("HMI sends OnVehicleData notification with handsOffSteering", common.onVehicleData, { true })
common.Step("RPC " .. rpc_unsub .. " on handsOffSteering parameter", common.processRPCSuccess, { rpc_unsub })

common.Title("Postconditions")
common.Step("Stop SDL", common.postcondition)
