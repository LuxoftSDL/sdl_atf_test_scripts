---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL doesn't transfer OnVehicleData notification to App if HMI sends notification with
-- invalid data
--
-- Preconditions:
-- 1) Update preloaded_pt file, add handsOffSteering parameter to VD_RPC group
-- 2) OnVehicleData notification is allowed by policies
-- 3) App is registered
-- 4) App is subscribed on handsOffSteering parameter
-- Steps:
-- 1) HMI sends VehicleInfo.OnVehicleData notification with invalid data to SDL
-- SDL does:
-- - a) ignored this notification and not transfer to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')


--[[ Local Variable ]]
local rpc_sub = "SubscribeVehicleData"

--[[ Local Function ]]
local function onVDInvalidData()
  common.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { handsOffSteering = 123 }) -- invalid data
  common.getMobileSession():ExpectNotification("OnVehicleData") :Times(0)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.precondition)
common.Step("Update preloaded file", common.updatedPreloadedPTFile)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerAppWOPTU)
common.Step("RPC " .. rpc_sub .. " on handsOffSteering parameter", common.processRPCSuccess, { rpc_sub })

common.Title("Test")
common.Step("HMI sends OnVD notification with invalid data", onVDInvalidData)

common.Title("Postconditions")
common.Step("Stop SDL", common.postcondition)
