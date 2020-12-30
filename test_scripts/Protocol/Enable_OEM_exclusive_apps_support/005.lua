---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local removeCreatedSession = true
local paramsToExclude = { "model", "modelYear", "trim", "systemHardwareVersion" }
local rpcServiceReqParams = {
  protocolVersion = common.setStringBsonValue("5.3.0")
}
local vehicleTypeData = {
  make = "Ford",
  model = "Focus",
  modelYear = "2015",
  trim = "SEL",
  ccpu_version = "12345_TV",
  systemHardwareVersion = "V4567_GJK"
}
local hmicap = common.setHMIcap(vehicleTypeData)

--[[ Local Functions ]]
local function getHMICap(pParamsToExclude)
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

local function registerApp(pParamsToExclude)
  local vehicleData  = common.cloneTable(vehicleTypeData)
  for _, value in pairs(pParamsToExclude) do
    for key in pairs(vehicleData) do
      if key == value then vehicleData[key] = nil end
    end
  end
  common.registerApp(vehicleData)
end

--[[ Scenario ]]
for _, parameter in common.spairs(paramsToExclude) do
  common.Title("Test with excluding " .. parameter .. " parameter")
  common.Title("Preconditions")
  common.Step("Clean environment", common.preconditions)
  local hmiCap = getHMICap({ parameter })
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.startWithCustomCap, { hmiCap })

  common.Title("Test")
  common.Step("Vehicle type data without " .. parameter .. " in StartServiceAck", common.startRpcService,
    { common.getRpcServiceAckParams(hmiCap) })
  common.Step("RAI, Vehicle type data in StartServiceAck", registerApp, { { parameter } })

  common.Title("Postconditions")
  common.Step("Stop SDL", common.postconditions, { removeCreatedSession })
end

common.Title("Test with excluding all not mandatory parameters")
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.startWithCustomCap, { getHMICap(paramsToExclude) })

common.Title("Test")
common.Step("Vehicle type data without all not mandatory params in StartServiceAck", common.startRpcService,
  { common.getRpcServiceAckParams(getHMICap(paramsToExclude)) })
common.Step("RAI, Vehicle type data in StartServiceAck", registerApp, { paramsToExclude })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
