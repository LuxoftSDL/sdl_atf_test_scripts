---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local paramsToExclude = { "make", "model", "modelYear", "trim", "systemHardwareVersion" }

--[[ Local Functions ]]
local function setHMICap(pParamToExclude)
  local defaultVehicleTypeInfoParam = common.cloneTable(common.vehicleTypeInfoParams.default)
  defaultVehicleTypeInfoParam[pParamToExclude] = nil
  local out = common.setHMIcap(defaultVehicleTypeInfoParam)
  return out
end

local function registerApp(pParamToExclude)
  local defaultVehicleTypeInfoParam = common.cloneTable(common.vehicleTypeInfoParams.default)
  defaultVehicleTypeInfoParam[pParamToExclude] = nil
  common.registerAppEx(defaultVehicleTypeInfoParam)
end

--[[ Scenario ]]
for _, parameter in common.spairs(paramsToExclude) do
  common.Title("Test with excluding " .. parameter .. " parameter")
  common.Title("Preconditions")
  common.Step("Clean environment", common.preconditions)
  local hmiCap = setHMICap(parameter)
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { hmiCap })

  common.Title("Test")
  common.Step("Vehicle type data without " .. parameter .. " in StartServiceAck", common.startRpcService,
    { common.getRpcServiceAckParams(hmiCap) })
  common.Step("Vehicle type data without " .. parameter .. " in RAI response", registerApp, { parameter })

  common.Title("Postconditions")
  common.Step("Stop SDL", common.postconditions)
end
