---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL is able to provide some part of the vehicle type data in RAI response after
--  receiving both GetVehicleType and GetSystemInfo responses
--
-- Steps:
-- 1. HMI provides some part of vehicle type data in BC.GetSystemInfo and VI.GetVehicleType responses:
--  - BC.GetSystemInfo(ccpu_version) and VI.GetVehicleType(make, model, modelYear, trim)
--  - BC.GetSystemInfo(ccpu_version, systemHardwareVersion) and VI.GetVehicleType(make, model, modelYear)
--  - BC.GetSystemInfo(ccpu_version, systemHardwareVersion) and VI.GetVehicleType(make, model, trim)
--  - BC.GetSystemInfo(ccpu_version, systemHardwareVersion) and VI.GetVehicleType(make, modelYear, trim)
--  - BC.GetSystemInfo(ccpu_version, systemHardwareVersion) and VI.GetVehicleType(model, modelYear, trim)
-- 2. App requests StartService(RPC) via 5th protocol
-- SDL does:
--  - Provide the vehicle type data received from HMI in StartServiceAck to the app
-- 3. App sends RAI request via 5th protocol
-- SDL does:
--  - Provide the vehicle type data received from HMI in RAI response to the app
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
