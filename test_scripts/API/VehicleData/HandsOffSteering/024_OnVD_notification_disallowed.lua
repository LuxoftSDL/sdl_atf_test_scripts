---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL doesn't transfer OnVehicleData notification to App if an app not allowed by policy with
-- new 'handsOffSteering' parameter
--
-- Preconditions:
-- 1) Update preloaded_pt file, add handsOffSteering parameter to VD_RPC group
-- 2) OnVehicleData notification is Not allowed by policies
-- 3) App is registered
-- 4) App is subscribed on handsOffSteering parameter
-- Steps:
-- 1) HMI sends valid VehicleInfo.OnVehicleData notification to SDL
-- SDL does:
-- - a) ignored this notification and not transfer to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')
local json = require("modules/json")

--[[ Local Variables ]]
local value = { true, false }
local rpc_sub = "SubscribeVehicleData"
local VDGroup = {
  rpcs = {
    SubscribeVehicleData = {
      hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
      parameters = {"handsOffSteering"}
    },
    OnVehicleData = {
      hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
      parameters = json.EMPTY_ARRAY
    }
  }
}

--[[ Local Function ]]
local function onVDNotAllowed(pHandsOffSteering)
  common.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { handsOffSteering = pHandsOffSteering })
  common.getMobileSession():ExpectNotification("OnVehicleData") :Times(0)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.precondition)
common.Step("Update preloaded file", common.updatedPreloadedPTFile, { VDGroup })
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerAppWOPTU)
common.Step("RPC " .. rpc_sub .. " on handsOffSteering parameter", common.processRPCSuccess, { rpc_sub })

common.Title("Test")
for _, v in pairs(value) do
  common.Step("HMI sends OnVD notification not allowed by policy, parameter-" .. tostring(v), onVDNotAllowed, { v })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postcondition)
