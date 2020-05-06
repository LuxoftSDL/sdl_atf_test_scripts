---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0266-New-vehicle-data-GearStatus.md
-- Description: SDL responds with `INVALID_DATA` resultCode on Get/Sub/Unsub/VehicleData requests with new 'gearStatus'
-- parameter in case App is registered with syncMsgVersion less than 6.2.
-- Preconditions:
-- 1) App is registered with syncMsgVersion=5.0
-- 2) New param `gearStatus` has since=6.2 in DB and API.
-- In case:
-- 1) App requests Get/Sub/UnsubVehicleData with gearStatus=true.
-- SDL does:
--  a) reject the request with resultCode INVALID_DATA as empty one.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/GearStatus/common')

-- [[ Test Configuration ]]
common.getParams(1).syncMsgVersion.majorVersion = 5
common.getParams(1).syncMsgVersion.minorVersion = 0

--[[ Local Functions ]]
local function ptuFunc(tbl)
  local VDgroup = {
    rpcs = {
      GetVehicleData = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"},
        parameters = {"gearStatus"}
      },
      SubscribeVehicleData = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"},
        parameters = {"gearStatus"}
      },
      UnsubscribeVehicleData = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"},
        parameters = {"gearStatus"}
      }
    }
  }
  tbl.policy_table.functional_groupings["GearStatus"] = VDgroup
  tbl.policy_table.app_policies[common.getParams(1).fullAppID].groups =
    { "Base-4", "GearStatus" }
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.precondition)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { ptuFunc })
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("GetVehicleData with gearStatus INVALID_DATA", common.processRPCFailure,
{ "GetVehicleData", "INVALID_DATA" })

common.Step("SubscribeVehicleData to gearStatus INVALID_DATA", common.processRPCFailure,
{ "SubscribeVehicleData", "INVALID_DATA" })

common.Step("UnsubscribeVehicleData with gearStatus INVALID_DATA", common.processRPCFailure,
{ "UnsubscribeVehicleData", "INVALID_DATA" })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
