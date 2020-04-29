---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL processes UnsubscribeVehicleData RPC with new 'handsOffSteering' parameter
--
-- Preconditions:
-- 1) Update preloaded_pt file, add handsOffSteering parameter to VD_RPC group
-- 2) RPC SubscribeVehicleData is allowed by policies
-- 3) App is registered
-- 4) App is subscribed on handsOffSteering parameter
-- Steps:
-- 1) App sends valid UnsubscribeVehicleData request to SDL
-- SDL does:
-- - a) transfer this request to HMI
-- Steps:
-- 2) HMI sends all VehicleInfo.UnsubscribeVehicleData response to SDL
-- SDL does:
-- - a) send UnsubscribeVehicleData response with (success = true, resultCode = SUCCESS") to App
-- - b) send OnHashChange notification to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Variables ]]
local rpc_sub = "SubscribeVehicleData"
local rpc_unsub = "UnsubscribeVehicleData"

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.precondition)
common.Step("Update preloaded file", common.updatedPreloadedPTFile)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerAppWOPTU)
common.Step("RPC " .. rpc_sub .. " on handsOffSteering parameter", common.processRPCSuccess, { rpc_sub })

common.Title("Test")
common.Step("RPC " .. rpc_unsub .. " on handsOffSteering parameter", common.processRPCSuccess, { rpc_unsub })

common.Title("Postconditions")
common.Step("Stop SDL", common.postcondition)
