---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local hmiCap = common.setHMIcap(common.vehicleTypeInfoParams.custom)
local rpcServiceAckParams = common.getRpcServiceAckParams(hmiCap)

local hmiCapWithOutRequests = common.cloneTable(hmiCap)
hmiCapWithOutRequests.RC.GetCapabilities.occurrence = 0
hmiCapWithOutRequests.UI.GetSupportedLanguages.occurrence = 0
hmiCapWithOutRequests.UI.GetCapabilities.occurrence = 0
hmiCapWithOutRequests.VR.GetSupportedLanguages.occurrence = 0
hmiCapWithOutRequests.VR.GetCapabilities.occurrence = 0
hmiCapWithOutRequests.TTS.GetSupportedLanguages.occurrence = 0
hmiCapWithOutRequests.TTS.GetCapabilities.occurrence = 0
hmiCapWithOutRequests.Buttons.GetCapabilities.occurrence = 0
hmiCapWithOutRequests.VehicleInfo.GetVehicleType.occurrence = 0
hmiCapWithOutRequests.UI.GetLanguage.occurrence = 0
hmiCapWithOutRequests.VR.GetLanguage.occurrence = 0
hmiCapWithOutRequests.TTS.GetLanguage.occurrence = 0

--[[ Local Functions ]]
local function updateHMICapabilitiesFile()
  local hmiCapTbl = common.getHMICapabilitiesFromFile()
  hmiCapTbl.VehicleInfo.vehicleType.make = common.vehicleTypeInfoParams.default.make
  hmiCapTbl.VehicleInfo.vehicleType.model = common.vehicleTypeInfoParams.default.model
  hmiCapTbl.VehicleInfo.vehicleType.modelYear = common.vehicleTypeInfoParams.default.modelYear
  hmiCapTbl.VehicleInfo.vehicleType.trim = common.vehicleTypeInfoParams.default.trim
  common.setHMICapabilitiesToFile(hmiCapTbl)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Update HMI capabilities", updateHMICapabilitiesFile)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { hmiCap })
common.Step("Ignition off", common.ignitionOff)

common.Title("Test")
common.Step("Ignition on, Start SDL, HMI does not send GetSystemInfo notification",
  common.start, { hmiCapWithOutRequests })
common.Step("Start RPC Service, Vehicle type data in StartServiceAck", common.startRpcService, { rpcServiceAckParams })
common.Step("Vehicle type data in RAI", common.registerAppEx, { common.vehicleTypeInfoParams.custom })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
