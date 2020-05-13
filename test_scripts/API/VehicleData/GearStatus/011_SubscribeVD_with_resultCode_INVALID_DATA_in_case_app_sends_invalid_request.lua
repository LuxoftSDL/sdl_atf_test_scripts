---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0266-New-vehicle-data-GearStatus.md
--
-- Description: SDL responds with `INVALID_DATA` resultCode in case App sends an invalid type of `gearStatus` parameter in
-- SubscribeVehicleData request.
--
-- In case:
-- 1) App sends invalid SubscribeVehicleData request to the SDL.
-- SDL does:
--  a) not transfer this request to HMI.
--  b) send SubscribeVehicleData response with (success:false, resultCode:`INVALID_DATA`) to mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/GearStatus/common')

--[[ Local Variables ]]
local invalidType = 12345

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("SubscribeVehicleData with invalid value for gearStatus param", common.processRPCFailure,
  { "SubscribeVehicleData", "INVALID_DATA", invalidType })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
