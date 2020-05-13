-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0266-New-vehicle-data-GearStatus.md
--
-- Description: SDL sends response `GENERIC_ERROR` to a mobile app if HMI sends a response with invalid data in
-- `gearStatus` structure.
--
-- Preconditions:
-- 1) App is subscribed to `gearStatus` data.
-- In case:
-- 1) App sends UnsubscribeVehicleData(gearStatus:true) request
-- SDL does:
--  a) transfer this request to HMI.
-- 2) HMI sends the invalid `gearStatus` structure in UnsubscribeVehicleData response
--  1) invalid parameter value
--  2) invalid parameter type
--  3) empty value
-- SDL does:
--  a) respond `GENERIC_ERROR` to mobile when default timeout is expired.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/GearStatus/common')

--[[ Local Variables ]]
local subUnsubResponse = {
  dataType = "VEHICLEDATA_GEARSTATUS",
  resultCode = "SUCCESS"
}

local invalidValue = {
  emptyValue = "",
  invalidType = 12345,
  invalidParamValue = "Invalid parameter value"
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)
common.Step("App subscribes to gearStatus data", common.subUnScribeVD, { "SubscribeVehicleData" })

common.Title("Test")
for p in pairs(subUnsubResponse) do
  common.Title("Check for " .. p .. " parameter")
  for k, v in pairs(invalidValue) do
    common.Step("HMI sends response with " ..k .. " for ".. p, common.invalidDataFromHMI,
      { "UnsubscribeVehicleData", common.responseTosubUnsubReq(), p, v })
  end
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
