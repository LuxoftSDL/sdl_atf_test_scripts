---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL rejects GetVehicleDate request with resultCode: "DISALLOWED" if an app not allowed by
-- policy with new 'handsOffSteering' parameter after PTU
--
-- Preconditions:
-- 1) Update preloaded_pt file, add handsOffSteering parameter to VD_RPC group
-- 2) RPC GetVehicleData is allowed by policies
-- 3) App is registered
-- Steps:
-- 1) App sends valid GetVehicleData request to SDL
-- SDL does:
-- - a) transfer this request to HMI
-- Steps:
-- 2) HMI sends all VehicleInfo.GetVehicleData response to SDL
-- SDL does:
-- - a) send GetVehicleData response with (success = true, resultCode = SUCCESS") to App
-- 4) PTU is performed and an app not allowed by policy
-- Steps:
-- 1) App sends valid GetVehicleData request to SDL
-- SDL does:
-- - a) send GetVehicleData response with (success = false, resultCode = DISALLOWED") to App
-- - b) not transfer this request to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

-- [[ Local Function ]]
local function ptUpdate(pt)
  pt.policy_table.app_policies[common.getParams().fullAppID].groups = { "Base-4" }
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.precondition)
common.Step("Update preloaded file", common.updatedPreloadedPTFile)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("RPC GetVehicleData", common.getVehicleData, { true })

common.Title("Test")
common.Step("Policy Table Update", common.policyTableUpdate, { ptUpdate })
common.Step("RPC GetVehicleData, DISALLOWED after PTU", common.getVDDisallowed)

common.Title("Postconditions")
common.Step("Stop SDL", common.postcondition)
