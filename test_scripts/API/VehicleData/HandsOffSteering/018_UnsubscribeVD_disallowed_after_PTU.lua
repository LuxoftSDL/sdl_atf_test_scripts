---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL rejects UnsubscribeVehicleData request with resultCode: "DISALLOWED" if an app not
-- allowed by policy with new 'handsOffSteering' parameter after PTU
--
-- Preconditions:
-- 1) Update preloaded_pt file, add handsOffSteering parameter to VD_RPC group
-- 2) RPC SubscribeVehicleData and UnsubscribeVehicleData are allowed by policies
-- 3) App is registered and subscribed on handsOffSteering parameter
-- Steps:
-- 1) App sends valid UnsubscribeVehicleData request to SDL
-- SDL does:
-- - a) transfer this request to HMI
-- Steps:
-- 2) HMI sends all VehicleInfo.UnsubscribeVehicleData response to SDL
-- SDL does:
-- - a) send UnsubscribeVehicleData response with (success = true, resultCode = SUCCESS") to App
-- - b) send OnHashChange notification to App
-- 4) App is subscribed on handsOffSteering parameter again
-- 5) PTU is performed and UnsubscribeVehicleData RPC not allowed by policy
-- 6) App sends valid UnsubscribeVehicleData request to SDL
-- SDL does:
-- - a) send UnsubscribeVehicleData response with (success = false, resultCode = DISALLOWED") to App
-- - b) not transfer this request to HMI
-- - c) not send OnHashChange notification to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Variables ]]
local rpc_sub = "SubscribeVehicleData"
local rpc_unsub = "UnsubscribeVehicleData"

--[[ Local Function ]]
local function ptUpdate(pt)
  pt.policy_table.app_policies[common.getParams().fullAppID].groups = { "Base-4" }
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.precondition)
common.Step("Update preloaded file", common.updatedPreloadedPTFile)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerAppWOPTU)
common.Step("RPC " .. rpc_sub .. " on handsOffSteering parameter", common.processRPCSuccess, { rpc_sub })
common.Step("Check allow " .. rpc_unsub .. " RPC", common.processRPCSuccess, { rpc_unsub })
common.Step("App subscribed again on handsOffSteering parameter", common.processRPCSuccess, { rpc_sub })

common.Title("Test")
common.Step("Policy Table Update", common.policyTableUpdate, { ptUpdate })
common.Step("RPC " .. rpc_unsub .. " on handsOffSteering parameter DISALLOWED after PTU",
  common.processRPCDisallowed, { rpc_unsub })

common.Title("Postconditions")
common.Step("Stop SDL", common.postcondition)
