---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0266-New-vehicle-data-GearStatus.md
--
-- Description: SDL successfully processes GetVehicleData with new `gearStatus` param.
--
-- In case:
-- 1) App sends GetVehicleData request with gearStatus=true to the SDL and this request is allowed by Policies.
-- SDL does:
--  a) transfer this request to HMI.
-- 2) HMI sends GetVehicleData response with all params of structure `gearStatus`.
-- SDL does:
--  a) send GetVehicleData response to mobile with all parameters in `gearStatus` structure.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/GearStatus/common')

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("GetVehicleData for gearStatus param", common.getVehicleData, { common.getGearStatusParams() })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
