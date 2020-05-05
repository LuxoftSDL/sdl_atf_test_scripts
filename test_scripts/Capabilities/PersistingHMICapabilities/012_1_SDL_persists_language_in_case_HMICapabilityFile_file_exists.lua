---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that SDL persists (VR/TTS/UI) languages in exist "hmi_capabilities_cache.json" file in case HMI sends
--  TTS/VR/UI.OnLanguageChange notification with appropriate language
--
-- Preconditions:
-- 1. hmi_capabilities_cache.json file doesn't exist on file system
-- 2. SDL and HMI are started
-- 3. HMI does not provide language capabilities (VR/TTS/UI.GetLanguage)
-- 4. SDL persists capability to "hmi_capabilities_cache.json" file in AppStorageFolder
-- Sequence:
-- 1. HMI sends "TTS/VR/UI.OnLanguageChange" notifications with language to SDL
--  a. SDL persists TTS/VR/UI.language in "hmi_capabilities_cache.json" file
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Local Functions ]]
local function noResponseGetLanguageHMIParams()
  local hmiCaps = common.getDefaultHMITable()
    hmiCaps.UI.GetLanguage = nil
    hmiCaps.VR.GetLanguage = nil
    hmiCaps.TTS.GetLanguage = nil
  return hmiCaps
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI", common.start, { noResponseGetLanguageHMIParams })

common.Title("Test")
common.Step("OnLanguageChange notification ", common.changeLanguage, { "FR-FR" })
common.Step("Check stored value to cache file", common.checkLanguageCapability, { "FR-FR" })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
