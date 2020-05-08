---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that SDL is compare saved ccpu_version parameter and received from HMI.
--  SDL does requested all capabilities from HMI in case ccpu_version do not match
--
-- Preconditions:
-- 1  Value of HMICapabilitiesCacheFile parameter is defined (hmi_capabilities_cache.json) in smartDeviceLink.ini file
-- 2. HMI capabilities cache file (hmi_capabilities_cache.json) doesn't exist on file system
-- 3. SDL and HMI are started
-- 4. HMI sends all HMI capabilities (VR/TTS/RC/UI etc) to SDL
-- 5. SDL stored capabilities to HMI capabilities cache file (hmi_capabilities_cache.json) in AppStorageFolder
-- 6. Ignition OFF/ON cycle performed
-- Sequence:
-- 1. HMI sends "BasicCommunication.GetSystemInfo" response with the different ccpu_version
--  a. sends all HMI capabilities request (VR/TTS/RC/UI etc)
-- 2. Ignition OFF/ON cycle performed
-- 3. HMI sends "BasicCommunication.GetSystemInfo" response with the same ccpu_version
--  a. not send HMI capabilities request (VR/TTS/RC/UI etc)
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Local Functions ]]
local function getHMIParamsWithOutRequests(pVersion)
  local hmiCapabilities = common.updateHMISystemInfo(pVersion)
  hmiCapabilities.RC.GetCapabilities.occurrence = 0
  hmiCapabilities.UI.GetSupportedLanguages.occurrence = 0
  hmiCapabilities.UI.GetCapabilities.occurrence = 0
  hmiCapabilities.VR.GetSupportedLanguages.occurrence = 0
  hmiCapabilities.VR.GetCapabilities.occurrence = 0
  hmiCapabilities.TTS.GetSupportedLanguages.occurrence = 0
  hmiCapabilities.TTS.GetCapabilities.occurrence = 0
  hmiCapabilities.Buttons.GetCapabilities.occurrence = 0
  hmiCapabilities.VehicleInfo.GetVehicleType.occurrence = 0
  hmiCapabilities.UI.GetLanguage.occurrence = 0
  hmiCapabilities.VR.GetLanguage.occurrence = 0
  hmiCapabilities.TTS.GetLanguage.occurrence = 0
  return hmiCapabilities
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI", common.start, { common.updateHMISystemInfo("cppu_version_1") })

common.Title("Test")
common.Step("Ignition off", common.ignitionOff)
common.Step("Ignition on, Start SDL, HMI sends different cppu_version",
  common.start, { common.updateHMISystemInfo("cppu_version_2") })
common.Step("Ignition off", common.ignitionOff)
common.Step("Ignition on, Start SDL, HMI sends the same cppu_version",
  common.start, { getHMIParamsWithOutRequests("cppu_version_2") })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
