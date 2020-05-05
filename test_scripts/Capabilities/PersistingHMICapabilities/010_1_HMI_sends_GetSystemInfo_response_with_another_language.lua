---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: SDL does not send all HMI Capabilities (VR/TTS/RC/UI etc) requests to HMI for subsequent ignition cycles
--  in case HMI sends BC.GetSystemInfo response with another language/wersCountryCode
--
-- Preconditions:
-- 1. HMI sends GetSystemInfo with ccpu_version = "ccpu_version_1", language = "EN-US", wersCountryCode = "wersCountryCode_1" to SDL
-- 2. HMI sends all capability to SDL
-- 3. SDL persists capability to "hmi_capabilities_cache.json" file in AppStorageFolder
-- 4. Ignition OFF/ON cycle performed
-- 5. SDL is started and send GetSystemInfo request
-- Sequence:
-- 1. HMI sends GetSystemInfo with another language = "FR-FR" to SDL
--   a) does not send request to HMI for all capability
-- 2. Ignition OFF/ON cycle performed
-- 3. HMI sends GetSystemInfo with another wersCountryCode = wersCountryCode_2 to SDL
--   a) does not send request to HMI for all capability
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Local Variables ]]
local ccpuVersion = "cppu_version_1"

--[[ Local Functions ]]
local function updateHMISystemInfo(pVersion, pLanguage, pWersCountryCode )
  local hmiValues = common.getDefaultHMITable()
  hmiValues.BasicCommunication.GetSystemInfo = {
    params = {
      ccpu_version = pVersion,
      language = pLanguage,
      wersCountryCode = pWersCountryCode
    }
  }
  return hmiValues
end

local function noRequestsGetHMIParams(pVersion, pLanguage, pWersCountryCode)
  local hmiValues = common.noRequestsGetHMIParams()
  hmiValues.BasicCommunication.GetSystemInfo = {
    params = {
      ccpu_version = pVersion,
      language = pLanguage,
      wersCountryCode = pWersCountryCode
    }
  }
  return hmiValues
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI", common.start, { updateHMISystemInfo(ccpuVersion, "EN-US", "wersCountryCode_1") })

common.Title("Test")
common.Step("Ignition off", common.ignitionOff)
common.Step("Ignition on, Start SDL, HMI sends GetSystemInfo with another language ",
  common.start, { noRequestsGetHMIParams(ccpuVersion, "FR-FR", "wersCountryCode_1") })
common.Step("Ignition off", common.ignitionOff)
common.Step("Ignition on, Start SDL, HMI sends GetSystemInfo with another wersCountryCode ",
  common.start, { noRequestsGetHMIParams(ccpuVersion, "FR-FR", "wersCountryCode_2") })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
