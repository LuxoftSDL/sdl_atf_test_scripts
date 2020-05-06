-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0266-New-vehicle-data-GearStatus.md
-- Description: SDL successfully processes GetVehicleData response if gearStatus structure contains one parameter.
-- In case:
-- 1) App sends GetVehicleData(gearStatus:true) request.
-- SDL does:
--  a) transfer this request to HMI.
-- 2) HMI sends the `gearStatus` structure with only one param in GetVehicleData response.
-- SDL does:
--  a) respond with resultCode:`SUCCESS` to app with only one param.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/GearStatus/common')

--[[ Local Functions ]]
local function getVDWithOneParam(pData)
  local cid = common.getMobileSession():SendRPC("GetVehicleData", { gearStatus = true })
  common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { gearStatus = true })
  :Do(function(_,data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { gearStatus = pData })
  end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS", gearStatus = pData })
  :ValidIf(function(_, data)
    return common.checkParam(data, "GetVehicleData")
  end)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.precondition)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)

common.Title("Test")
for k,v in pairs(common.gearStatusData) do
  common.Step("HMI sends response with one " .. k.. " parameter", getVDWithOneParam, { { [k] = v } })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postcondition)
