-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0266-New-vehicle-data-GearStatus.md
-- Description: SDL sends response `GENERIC_ERROR` to mobile app if HMI sends response with invalid `gearStatus` structure:
-- userSelectedGear, actualGear, transmissionType.
-- In case:
-- 1) App sends GetVehicleData(gearStatus:true) request.
-- SDL does:
--  a) transfer this request to HMI.
-- 2) HMI sends the invalid `gearStatus` structure in GetVehicleData response:
--  1) invalid parameter value
--  2) invalid parameter type
--  3) empty value
--  4) empty structure
-- SDL does:
--  a) respond `GENERIC_ERROR` to mobile when default timeout is expired.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/GearStatus/common')

--[[ Local Function ]]
local function getVDWithEmptyStructure()
  local cid = common.getMobileSession():SendRPC("GetVehicleData", { gearStatus = true })
  common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { gearStatus = true })
  :Do(function(_,data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { gearStatus = {} })
  end)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.precondition)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)

common.Title("Test")
for p in pairs(common.gearStatusData) do
  common.Title("Check for " .. p .. " parameter")
  for k, v in pairs(common.invalidValue) do
    common.Step("HMI sends response with " ..k .. " for ".. p, common.invalidDataFromHMI,
      { "GetVehicleData", common.gearStatus(), p, v } )
  end
end
common.Step("HMI sends response with empty gearStatus structure", getVDWithEmptyStructure)

common.Title("Postconditions")
common.Step("Stop SDL", common.postcondition)
