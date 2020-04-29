---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL rejects UnsubscribeVehicleData request with resultCode: "DISALLOWED" if an app not
-- allowed by policy with new 'handsOffSteering' parameter
--
-- Preconditions:
-- 1) Update preloaded_pt file, add handsOffSteering parameter to VD_RPC group
-- 2) RPC UnsubscribeVehicleData is allowed by policies only for App_1
-- 3) App_1 and App_2 are registered and Subscribed on handsOffSteering parameter
-- Steps:
-- 1) App_1 sends valid UnsubscribeVehicleData request to SDL
-- SDL does:
-- - a) respond SUCCESS, success:true and parameter value received from HMI to App_1
-- - b) not transfer this request to HMI
-- - c) send OnHashChange notification to App_1
-- Steps:
-- 2) App_2 sends valid UnsubscribeVehicleData request to SDL
-- SDL does:
-- - a) send UnsubscribeVehicleData response with (success = false, resultCode = DISALLOWED") to App_2
-- - b) not transfer this request to HMI
-- - c) not send OnHashChange notification to App_2
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')
local utils = require("user_modules/utils")
local json = require("modules/json")

--[[ Local Variables ]]
local rpc_sub = "SubscribeVehicleData"
local rpc_unsub = "UnsubscribeVehicleData"

--[[ Local Functions ]]
local function updatedPreloadedPTFile()
  local pt = common.getPreloadedPT()
  local pGroups1 = {
    rpcs = {
      SubscribeVehicleData = {
        hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
        parameters = {"handsOffSteering"}
      }
    }
  }
  local pGroups2 = {
    rpcs = {
      UnsubscribeVehicleData = {
        hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
        parameters = {"handsOffSteering"}
      }
    }
  }
  pt.policy_table.functional_groupings["Group1"] = pGroups1
  pt.policy_table.functional_groupings["Group2"] = pGroups2
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  pt.policy_table.app_policies[common.getParams(1).fullAppID] = utils.cloneTable(pt.policy_table.app_policies.default)
  pt.policy_table.app_policies[common.getParams(1).fullAppID].groups = { "Base-4", "Group1", "Group2" }
  pt.policy_table.app_policies[common.getParams(2).fullAppID] = utils.cloneTable(pt.policy_table.app_policies.default)
  pt.policy_table.app_policies[common.getParams(2).fullAppID].groups = { "Base-4", "Group1" }
  common.setPreloadedPT(pt)
end

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
common.Step("Update preloaded file", updatedPreloadedPTFile)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App_1", common.registerAppWOPTU, { 1 })
common.Step("RPC " .. rpc_sub .. " on handsOffSteering parameter for App_1", common.processRPCSuccess, { rpc_sub, 1 })
common.Step("Register App_2", common.registerAppWOPTU, { 2 })
common.Step("RPC " .. rpc_sub .. " on handsOffSteering parameter for App_2", processRPCSuccess, { rpc_sub, 2 })

common.Title("Test")
common.Step("RPC " .. rpc_unsub .. " on handsOffSteering parameter for App_1", processRPCSuccess, { rpc_unsub, 1 })
common.Step("RPC " .. rpc_unsub .. " on handsOffSteering parameter for App_2",
  common.processRPCDisallowed, { rpc_unsub, 2 })

common.Title("Postconditions")
common.Step("Stop SDL", common.postcondition)
