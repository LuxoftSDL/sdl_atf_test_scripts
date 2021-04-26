---------------------------------------------------------------------------------------------------
-- Description: Check that SDL filters out param from GetVehicleData request
-- if <vd_param> parameter is not allowed by policy after PTU
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) GetVehicleData RPC and <vd_param> parameter are allowed by policies
-- 3) App is registered
--
-- In case:
-- 1) App sends valid GetVehicleData(<vd_param>=true) request to SDL
-- SDL does:
-- - a) transfer this request to HMI
-- 2) HMI sends VI.GetVehicleData response with <vd_param> data to SDL
-- SDL does:
-- - a) send GetVehicleData response with (success = true, resultCode = "SUCCESS",
-- <vd_param> = <data received from HMI>) to App
-- 3) PTU is performed with disabling permissions for <vd_param> parameter
-- 4) App sends valid GetVehicleData(<vd_param>=true) request to SDL
-- SDL does:
-- - a) send GetVehicleData response to App but filter out disallowed <vd_param> parameter
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/common')

--[[ Local Variables ]]
local all_params = {}
for param in pairs(common.getVDParams(true)) do
  table.insert(all_params, param)
end
if #all_params == 0 then all_params = common.json.EMPTY_ARRAY end

--[[ Local Function ]]
local function getVDGroup(pDisallowedParam)
  local params = {}
  for param in pairs(common.getVDParams()) do
    if param ~= pDisallowedParam then table.insert(params, param) end
  end
  if #params == 0 then params = common.json.EMPTY_ARRAY end
  return {
    rpcs = {
      [common.rpc.get] = {
        hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
        parameters = params
      }
    }
  }
end

local function policyTableUpdate(pDisallowedParam)
  local function ptUpdate(pt)
    pt.policy_table.functional_groupings["NewTestCaseGroup"] = getVDGroup(pDisallowedParam)
    pt.policy_table.app_policies[common.getAppParams().fullAppID].groups = { "Base-4", "NewTestCaseGroup" }
  end
  common.policyTableUpdate(ptUpdate)
end

--[[ Scenario ]]
for param in common.spairs(common.getVDParams()) do
  common.runner.Title("VD parameter: " .. param)
  common.runner.Title("Preconditions")
  common.runner.Step("Clean environment and update preloaded_pt file", common.preconditions)
  common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  common.runner.Step("Register App", common.registerApp)
  common.runner.Step("RPC GetVehicleData, SUCCESS", common.getVehicleDataMultipleParams, { all_params })

  common.runner.Title("Test")
  common.runner.Step("PTU with disabling permissions for VD parameter", policyTableUpdate, { param })
  common.runner.Step("RPC " .. common.rpc.get .. " filtered after PTU", common.getVehicleDataMultipleParams,
    { all_params, nil, param })

  common.runner.Title("Postconditions")
  common.runner.Step("Stop SDL", common.postconditions)
end
