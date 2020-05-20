---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0261-New-vehicle-data-WindowStatus.md
--
-- Description: Check that SDL rejects the GetVehicleData request with resultCode DISALLOWED
-- if app tries to get vehicle data and `windowStatus` parameter is not present in apps assigned policies after PTU.
--
-- Preconditions:
-- 1) GetVehicleData RPC, `windowStatus` parameter are allowed by policies.
-- 2) App sends valid GetVehicleData request with windowStatus=true to the SDL.
-- 3) SDL processes this requests successfully.
-- In case:
-- 1) Policy Table Update is performed and `windowStatus` parameter is unassigned for the app.
-- 2) App sends GetVehicleData requests with windowStatus=true to the SDL.
-- SDL does:
--  a) send GetVehicleData(success:false, "DISALLOWED") response to the mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/WindowStatus/common')

--[[ Local Variables ]]
local resultCode = "DISALLOWED"
local rpc = "GetVehicleData"

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)
common.Step("GetVehicleData for windowStatus", common.getVehicleData, { common.getWindowStatusParams() })

common.Title("Test")
common.Step("PTU is performed, windowStatus is unassigned for the app",
  common.policyTableUpdate, { common.pTUpdateFunc })
common.Step("GetVehicleData for windowStatus " .. resultCode,
  common.processRPCFailure, { rpc, resultCode })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)