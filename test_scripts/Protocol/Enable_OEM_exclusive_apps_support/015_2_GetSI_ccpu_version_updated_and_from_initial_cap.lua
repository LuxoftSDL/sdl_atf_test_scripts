---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
-- Description: SDL is able to provide the updated vehicle type data to the mobile app in case ccpu version is updated
--  in the second SDL ignition cycle and HMI does not respond to VI.GetVehicleType request
--
-- Steps:
-- 1. HMI responds with new value of ccpu_version to BC.GetSystemInfo request in the second ignition cycle
-- SDL does:
--  - Remove the cache file with hmi capabilities
--  - Request getting of all HMI capabilities and VI.GetVehicleType RPC
-- 2. HMI does not respond to VI.GetVehicleType request
-- 3. App requests StartService(RPC) via 5th protocol
-- SDL does:
--  - Provide systemHardwareVersion and systemSoftwareVersion values received from HMI in StartServiceAck to the app
--  - Provide the values for make, model, modelYear, trim parameters from the initial SDL capabilities file defined in
--     .ini file in HMICapabilities parameter in StartServiceAck to the app
-- 4. App requests RAI
-- SDL does:
--  - Provide systemHardwareVersion and systemSoftwareVersion values received from HMI in RAI response to the app
--  - Provide the values for make, model, modelYear, trim parameters from the initial SDL capabilities file defined in
--     .ini file in HMICapabilities parameter in RAI response to the app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local initialVehicleTypeParams = {
  make = "OEM2",
  model = "Ranger",
  modelYear = "2021",
  trim = "Base"
}

local vehicleTypeInfoParams = {
  make = initialVehicleTypeParams.make,
  model = initialVehicleTypeParams.model,
  modelYear = initialVehicleTypeParams.modelYear,
  trim = initialVehicleTypeParams.trim,
  ccpu_version = common.vehicleTypeInfoParams.custom.ccpu_version,
  systemHardwareVersion = common.vehicleTypeInfoParams.custom.systemHardwareVersion
}

local defaultHmiCap = common.setHMIcap(common.vehicleTypeInfoParams.default)

--[[ Local Functions ]]
local function getRpcServiceAckParams(pVehicleTypeInfoParams)
  local ackParams = {
    make = common.setStringBsonValue(pVehicleTypeInfoParams.make),
    model = common.setStringBsonValue(pVehicleTypeInfoParams.model),
    modelYear = common.setStringBsonValue(pVehicleTypeInfoParams.modelYear),
    trim = common.setStringBsonValue(pVehicleTypeInfoParams.trim),
    systemSoftwareVersion = common.setStringBsonValue(pVehicleTypeInfoParams.ccpu_version),
    systemHardwareVersion = common.setStringBsonValue(pVehicleTypeInfoParams.systemHardwareVersion)
  }
  for key, KeyValue in pairs(ackParams) do
    if not KeyValue.value then
      ackParams[key] = nil
    end
  end
  return ackParams
end

local function startNoResponseGetVehicleType(pHmiCap)
  local hmiCap = common.setHMIcap(pHmiCap)
  hmiCap.VehicleInfo.GetVehicleType = nil
  common.start(hmiCap)
end

local function updateHMICapabilitiesFile(pVehicleTypeParams)
  local hmiCapTbl = common.getHMICapabilitiesFromFile()
  hmiCapTbl.VehicleInfo.vehicleType.make = pVehicleTypeParams.make
  hmiCapTbl.VehicleInfo.vehicleType.model = pVehicleTypeParams.model
  hmiCapTbl.VehicleInfo.vehicleType.modelYear = pVehicleTypeParams.modelYear
  hmiCapTbl.VehicleInfo.vehicleType.trim = pVehicleTypeParams.trim
  common.setHMICapabilitiesToFile(hmiCapTbl)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Update HMI capabilities", updateHMICapabilitiesFile, { initialVehicleTypeParams })
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { defaultHmiCap })
common.Step("Ignition off", common.ignitionOff)

common.Title("Test")
common.Step("Start SDL, HMI, connect Mobile, start Session",
  startNoResponseGetVehicleType, { common.vehicleTypeInfoParams.custom })
common.Step("Start RPC Service, Vehicle type data in StartServiceAck",
  common.startRpcService, { getRpcServiceAckParams(vehicleTypeInfoParams) })
common.Step("Vehicle type data in RAI", common.registerAppEx, { vehicleTypeInfoParams })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
