---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0266-New-vehicle-data-GearStatus.md
-- Description: SDL responds with `INVALID_DATA` resultCode in case App sends an invalid type of `gearStatus` parameter in
-- UnsubscribeVehicleData request.
-- Preconditions:
-- 1) App is subscribed to `gearStatus` data.
-- In case:
-- 1) App sends invalid UnsubscribeVehicleData request to the SDL.
-- SDL does:
--  a) not transfer this request to HMI.
--  b) send UnsubscribeVehicleData response with (success:false, resultCode:`INVALID_DATA`) to mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/GearStatus/common')

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.precondition)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("UnsubscribeVehicleData with invalid request for gearStatus param", common.processRPCFailure,
  { "UnsubscribeVehicleData", "INVALID_DATA", common.invalidValue.invalidType })

common.Title("Postconditions")
common.Step("Stop SDL", common.postcondition)
