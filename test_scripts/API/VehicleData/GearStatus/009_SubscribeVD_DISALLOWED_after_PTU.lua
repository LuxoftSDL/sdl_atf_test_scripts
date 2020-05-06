---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0266-New-vehicle-data-GearStatus.md
-- Description: SDL rejects the request with resultCode:`DISALLOWED` if app tries to subscribe to 'gearStatus' vehicle data
-- and parameter 'gearStatus' is not present in apps assigned policies after PTU.
-- Preconditions:
-- 1) `gearStatus` param exists in app's assigned policies.
-- 2) App sends valid SubscribeVehicleData request with gearStatus=true to the SDL.
-- 3) and SDL processes this requests successfully.
-- In case:
-- 1) Policy Table Update is performed and "gearStatus" param is unassigned for the app.
-- 2) App re-sends SubscribeVehicleData request with gearStatus=true to the SDL.
-- SDL does:
--  a) send response to SubscribeVehicleData with (success:false, resultCode:`DISALLOWED`) to the mobile app.
-- 3) HMI sends valid OnVehicleData notification with all parameters of `gearStatus` structure.
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
common.Step("App sends GetVehicleData for gearStatus", common.getVehicleData, { common.gearStatusData })
common.Step("App subscribes to gearStatus data", common.subUnScribeVD, { "SubscribeVehicleData" })

common.Title("Test")
common.Step("PTU is performed, gearStatus is unassigned for the app", common.policyTableUpdate, { common.pTUpdateFunc })
common.Step("SubscribeVehicleData for gearStatus DISALLOWED", common.processRPCFailure, { "SubscribeVehicleData", "DISALLOWED" })
common.Step("OnVehicleData with gearStatus data", common.sendOnVehicleData, { common.gearStatusData, notExpected })

common.Title("Postconditions")
common.Step("Stop SDL", common.postcondition)
