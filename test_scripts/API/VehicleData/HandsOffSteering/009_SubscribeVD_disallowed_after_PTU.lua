---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL rejects SubscribeVehicleData request with resultCode: "DISALLOWED" if an app not allowed
-- by policy with new 'handsOffSteering' parameter after PTU
--
-- Preconditions:
-- 1) Update preloaded_pt file, add handsOffSteering parameter to VD_RPC group
-- 2) RPC SubscribeVehicleData is allowed by policies
-- 3) App is registered
-- Steps:
-- 1) App sends valid SubscribeVehicleData request to SDL
-- SDL does:
-- - a) transfer this request to HMI
-- Steps:
-- 2) HMI sends all VehicleInfo.SubscribeVehicleData response to SDL
-- SDL does:
-- - a) send SubscribeVehicleData response with (success = true, resultCode = SUCCESS") to App
-- - b) send OnHashChange notification to App
-- 4) PTU is performed and SubscribeVehicleData RPC not allowed by policy
-- Steps:
-- 1) App sends valid SubscribeVehicleData request to SDL
-- SDL does:
-- - a) send SubscribeVehicleData response with (success = false, resultCode = DISALLOWED") to App
-- - b) not transfer this request to HMI
-- - c) not send OnHashChange notification to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Variable ]]
local rpc = "SubscribeVehicleData"

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
common.Step("RPC " .. rpc .. " on handsOffSteering parameter App", common.processRPCSuccess, { rpc })

common.Title("Test")
common.Step("Policy Table Update", common.policyTableUpdate, { ptUpdate })
common.Step("RPC " .. rpc .. " on handsOffSteering parameter DISALLOWED after PTU", common.processRPCDisallowed, { rpc })

common.Title("Postconditions")
common.Step("Stop SDL", common.postcondition)
