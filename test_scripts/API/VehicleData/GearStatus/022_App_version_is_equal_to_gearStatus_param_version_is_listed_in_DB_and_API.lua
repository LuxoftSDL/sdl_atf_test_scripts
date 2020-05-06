---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0266-New-vehicle-data-GearStatus.md
-- Description: SDL successfully processes Get/Sub/Unsub/VehicleData requests with new 'gearStatus' parameter in case
-- App is registered with syncMsgVersion is equal to 6.2.
-- Preconditions:
-- 1) App is registered with syncMsgVersion=6.2
-- 2) New param `gearStatus` has since=6.2 in DB and API.
-- In case:
-- 1) App requests Get/Sub/UnsubVehicleData with gearStatus=true.
-- 2) HMI sends valid OnVehicleData notification with all parameters of `gearStatus` structure.
-- SDL does:
--  a) process the requests successful.
--  b) process the OnVehicleData notification and transfer it to mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/GearStatus/common')

-- [[ Test Configuration ]]
common.getParams(1).syncMsgVersion.majorVersion = 6
common.getParams(1).syncMsgVersion.minorVersion = 2

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
      },
      OnVehicleData = {
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
common.Step("GetVehicleData for gearStatus", common.getVehicleData, { common.gearStatusData })
common.Step("App subscribes to gearStatus data", common.subUnScribeVD, { "SubscribeVehicleData" })
common.Step("OnVehicleData with gearStatus data", common.sendOnVehicleData, { common.gearStatusData })
common.Step("App unsubscribes to gearStatus data", common.subUnScribeVD, { "UnsubscribeVehicleData" })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
