---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0266-New-vehicle-data-GearStatus.md
--
-- Description: SDL rejects the request with resultCode:`DISALLOWED` if app tries to get `gearStatus` vehicle data in
-- case `gearStatus` parameter does not exist in apps assigned policies.
--
-- In case:
-- 1) `gearStatus` param does not exist in app's assigned policies.
-- 2) App sends valid GetVehicleData request with gearStatus=true to the SDL.
-- SDL does:
--  a) send response GetVehicleData with (success:false, resultCode:`DISALLOWED`) to the mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/GearStatus/common')

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions, { false })
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("GetVehicleData for gearStatus DISALLOWED", common.processRPCFailure, { "GetVehicleData", "DISALLOWED" })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
