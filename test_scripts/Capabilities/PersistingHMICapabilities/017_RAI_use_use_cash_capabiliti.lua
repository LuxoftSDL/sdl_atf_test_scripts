---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that the SDL takes parameters from hmi_capabilities_cache.json in case
-- HMI does not send successful GetCapabilities/GetLanguage/GetVehicleType responses due to timeout

-- Preconditions:
-- 1) hmi_capabilities_cache.json file doesn't exist on file system
-- 2) HMI and SDL are started
-- Steps:
-- 1) HMI does not provide any Capability
-- SDL does:
--  a) use cash capability from hmi_capabilities_cache.json file

---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Local Variables ]]
local appSessionId = 1
local hmiCapabilities = common.getDefaultHMITable()

local capRaiResponse = {
  buttonCapabilities = hmiCapabilities.Buttons.GetCapabilities.params.capabilities,
  vehicleType = hmiCapabilities.VehicleInfo.GetVehicleType.params.vehicleType,
  audioPassThruCapabilities = hmiCapabilities.UI.GetCapabilities.params.audioPassThruCapabilities,
  hmiDisplayLanguage =  hmiCapabilities.UI.GetCapabilities.params.language,
  language = hmiCapabilities.VR.GetLanguage.params.language, -- or TTS.language
  pcmStreamCapabilities = hmiCapabilities.UI.GetCapabilities.params.pcmStreamCapabilities,
  hmiZoneCapabilitie = hmiCapabilities.UI.GetCapabilities.params.hmiZoneCapabilitie,
  softButtonCapabilities = hmiCapabilities.UI.GetCapabilities.params.softButtonCapabilities,
  displayCapabilities = hmiCapabilities.UI.GetCapabilities.params.displayCapabilities,
  vrCapabilities = hmiCapabilities.VR.GetCapabilities.params.capabilities,
  speechCapabilities = hmiCapabilities.TTS.GetCapabilities.params.capabilities
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Update HMI capabilities", common.updateHMICapabilities)

common.Title("Test")
common.Step("Ignition on, Start SDL, HMI", common.start)
common.Step("Check that capability file exists", common.checkIfExistCapabilityFile)
common.Step("Ignition off", common.ignitionOff)
common.Step("Ignition on, Start SDL, HMI", common.start, { common.noRequestsGetHMIParam() })
common.Step("App registration", common.registerApp, { appSessionId, capRaiResponse })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
