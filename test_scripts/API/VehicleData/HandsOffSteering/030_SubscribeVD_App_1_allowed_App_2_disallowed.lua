---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL rejects SubscribeVehicleData request with resultCode: "DISALLOWED" if an app not allowed
-- by policy with new 'handsOffSteering' parameter
--
-- Preconditions:
-- 1) Update preloaded_pt file, add handsOffSteering parameter to VD_RPC group
-- 2) RPC SubscribeVehicleData is allowed by policies only for App_1
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
-- - a) respond DISALLOWED, success:false to mobile application
-- - b) not transfer this request to HMI
-- - c) send not OnHashChange notification to App_2
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')
local utils = require("user_modules/utils")
local json = require("modules/json")

--[[ Local Variables ]]
local rpc_sub = "SubscribeVehicleData"

--[[ Local Function ]]
local function updatedPreloadedPTFile()
  local pt = common.getPreloadedPT()
  local pGroups = {
    rpcs = {
      SubscribeVehicleData = {
        hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
        parameters = {"handsOffSteering"}
      }
    }
  }
  pt.policy_table.functional_groupings["NewTestCaseGroup"] = pGroups
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  pt.policy_table.app_policies[common.getParams(1).fullAppID] = utils.cloneTable(pt.policy_table.app_policies.default)
  pt.policy_table.app_policies[common.getParams(1).fullAppID].groups = { "Base-4", "NewTestCaseGroup" }
  pt.policy_table.app_policies[common.getParams(2).fullAppID] = utils.cloneTable(pt.policy_table.app_policies.default)
  pt.policy_table.app_policies[common.getParams(2).fullAppID].groups = { "Base-4" }
  common.setPreloadedPT(pt)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.precondition)
common.Step("Update preloaded file", updatedPreloadedPTFile)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App_1", common.registerAppWOPTU, { 1 })
common.Step("RPC " .. rpc_sub .. " on handsOffSteering parameter for App_1", common.processRPCSuccess, { rpc_sub, 1 })

common.Title("Test")
common.Step("Register App_2", common.registerAppWOPTU, { 2 })
common.Step("RPC " .. rpc_sub .. " on handsOffSteering parameter for App_2 DISALLOWED",
  common.processRPCDisallowed, { rpc_sub, 2 })

common.Title("Postconditions")
common.Step("Stop SDL", common.postcondition)
