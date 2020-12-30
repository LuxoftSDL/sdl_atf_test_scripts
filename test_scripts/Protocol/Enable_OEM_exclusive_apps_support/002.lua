---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local paramsToExclude = { "model", "modelYear", "trim", "systemHardwareVersion" }
local vehicleTypeData = {
  make = "Ford",
  model = "Focus",
  modelYear = "2015",
  trim = "SEL",
  ccpu_version = "12345_TV",
  systemHardwareVersion = "V4567_GJK"
}
local hmicap = common.setHMIcap(vehicleTypeData)
local removeCreatedSession = true

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

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
