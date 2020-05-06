---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0266-New-vehicle-data-GearStatus.md
-- Description: SDL successful processes UnsubscribeVehicleData RPC with `gearStatus` param.
-- In case:
-- 1) App is subscribed to `gearStatus` data.
-- 2) App sends UnsubscribeVehicleData request with gearStatus=true to the SDL and this request is allowed by Policies.
-- SDL does:
--  a) transfer this requests to HMI.
-- 3) HMI responds with `SUCCESS` result to UnsubscribeVehicleData request.
-- SDL does:
--  a) respond with resultCode:`SUCCESS` to mobile application for `gearStatus` param.
-- 4) HMI sends valid OnVehicleData notification with all parameters of `gearStatus` structure.
-- SDL does:
--  a) ignore this notification.
--  b) not send OnVehicleData notification to mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/GearStatus/common')

--[[ Local Variables ]]
local notExpected = 0

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.precondition)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)
common.Step("App subscribes to gearStatus data", common.subUnScribeVD, { "SubscribeVehicleData" })
common.Step("OnVehicleData with gearStatus data", common.sendOnVehicleData, { common.gearStatusData })

common.Title("Test")
common.Step("App unsubscribes from gearStatus data", common.subUnScribeVD, { "UnsubscribeVehicleData" })
common.Step("OnVehicleData with gearStatus data", common.sendOnVehicleData, { common.gearStatusData, notExpected })

common.Title("Postconditions")
common.Step("Stop SDL", common.postcondition)