---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local paramsToExclude = { "make", "model", "modelYear", "trim", "systemHardwareVersion" }

--[[ Local Functions ]]
local function setHMICap(pParamsToExclude)
  local out = common.setHMIcap(common.vehicleTypeInfoParams.default)
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
  local vehicleData  = common.cloneTable(common.vehicleTypeInfoParams.default)
  for _, value in pairs(pParamsToExclude) do
    for key in pairs(vehicleData) do
      if key == value then vehicleData[key] = nil end
    end
  end
  common.registerAppEx(vehicleData)
end

--[[ Scenario ]]
for _, parameter in common.spairs(paramsToExclude) do
  common.Title("Test with excluding " .. parameter .. " parameter")
  common.Title("Preconditions")
  common.Step("Clean environment", common.preconditions)
  local hmiCap = setHMICap({ parameter })
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { hmiCap })

  common.Title("Test")
  common.Step("Vehicle type data without " .. parameter .. " in StartServiceAck", common.startRpcService,
    { common.getRpcServiceAckParams(hmiCap) })
  common.Step("Vehicle type data without " .. parameter .. " in RAI response", registerApp, {{ parameter }})

  common.Title("Postconditions")
  common.Step("Stop SDL", common.postconditions)
end
