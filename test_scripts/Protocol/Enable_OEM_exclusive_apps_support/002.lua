---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local paramsToExclude = { "model", "modelYear", "trim", "systemHardwareVersion" }
local rpcServiceReqParams = {
  protocolVersion = common.setStringBsonValue("5.3.0")
}
local hmicap = common.getCapWithMandatoryExp()

local getVehicleTypeParams = hmicap.VehicleInfo.GetVehicleType.params.vehicleType
getVehicleTypeParams.make = "Ford"
getVehicleTypeParams.model = "Focus"
getVehicleTypeParams.modelYear = 2015
getVehicleTypeParams.trim = "SEL"

local getSystemInfoParams = hmicap.BasicCommunication.GetSystemInfo.params
getSystemInfoParams.ccpu_version = "12345_TV"
getSystemInfoParams.systemHardwareVersion = "V4567_GJK"

--[[ Local Functions ]]
local function getHMICapabilities(pParamsToExclude)
  local out = common.cloneTable(hmicap)
  for _, value in pairs(pParamsToExclude) do
    for key in pairs(out.VehicleInfo.GetVehicleType.params.vehicleType) do
      if key == value then out.VehicleInfo.GetVehicleType.params.vehicleType[key] = nil end
    end
    for key in pairs(out.BasicCommunication.GetSystemInfo.params) do
      if key == value then out.BasicCommunication.GetSystemInfo.params[key] = nil end
    end
  end
  return out
end

--[[ Scenario ]]
for _, parameter in common.spairs(paramsToExclude) do
  common.Title("Test with excluding " .. parameter .. " parameter")
  common.Title("Preconditions")
  common.Step("Clean environment", common.preconditions)
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.startWithCustomCap,
    { getHMICapabilities({ parameter })})

  common.Title("Test")
  common.Step("Vehicle type data without " .. parameter .. " in StartServiceAck", common.startServiceUnprotectedACK,
    { 1, common.serviceType.RPC, rpcServiceReqParams, common.getRpcServiceAckParams(getHMICapabilities({ parameter }))})

  common.Title("Postconditions")
  common.Step("Stop SDL", common.postconditions)
end

common.Title("Test with excluding all not mandatory parameters")
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.startWithCustomCap,
  { getHMICapabilities(paramsToExclude) })

common.Title("Test")
common.Step("Vehicle type data without all not mandatory params in StartServiceAck", common.startServiceUnprotectedACK,
  { 1, common.serviceType.RPC, rpcServiceReqParams, common.getRpcServiceAckParams(getHMICapabilities(paramsToExclude))})

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
