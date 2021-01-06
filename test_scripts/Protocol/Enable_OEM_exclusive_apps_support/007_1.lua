---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local vehicleTypeInfoParams = {
  make = common.vehicleTypeInfoParams.default.make,
  model = common.vehicleTypeInfoParams.default.model,
  modelYear = common.vehicleTypeInfoParams.default.modelYear,
  trim = common.vehicleTypeInfoParams.default.trim,
  ccpu_version = common.vehicleTypeInfoParams.custom.ccpu_version,
  systemHardwareVersion = common.vehicleTypeInfoParams.custom.systemHardwareVersion
}

--[[ Local Functions ]]
local function updateHMICapabilitiesFile()
  local hmiCapTbl = common.getHMICapabilitiesFromFile()
  hmiCapTbl.VehicleInfo.vehicleType.make = common.vehicleTypeInfoParams.default.make
  hmiCapTbl.VehicleInfo.vehicleType.model = common.vehicleTypeInfoParams.default.model
  hmiCapTbl.VehicleInfo.vehicleType.modelYear = common.vehicleTypeInfoParams.default.modelYear
  hmiCapTbl.VehicleInfo.vehicleType.trim = common.vehicleTypeInfoParams.default.trim
  common.setHMICapabilitiesToFile(hmiCapTbl)
end

local function startErrorResponseGetVehicleType()
  local hmiCap = common.setHMIcap(common.vehicleTypeInfoParams.custom)
  hmiCap.VehicleInfo.GetVehicleType = nil
  common.startWithCustomCap(hmiCap)
  common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleType")
  :Do(function(_, data)
    common.getHMIConnection():SendError(data.id, data.method, "GENERIC_ERROR", "info message")
  end)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Update HMI capabilities", updateHMICapabilitiesFile)
common.Step("Start SDL, HMI sends GetSystemInfo(GENERIC_ERROR) response", startErrorResponseGetVehicleType )

common.Title("Test")
common.Step("Start RPC Service, Vehicle type data in StartServiceAck", common.startRpcService, { vehicleTypeInfoParams })
common.Step("Vehicle type data in RAI", common.registerAppEx, { vehicleTypeInfoParams })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)

