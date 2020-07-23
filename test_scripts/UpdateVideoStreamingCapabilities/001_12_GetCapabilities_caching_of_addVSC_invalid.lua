-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0296-Update-video-streaming-capabilities-during-ignition-cycle.md
--
-- Description: SDL does not persist the videoStreamingCapability received from HMI
--  in UI.GetCapabilities response in case HMI responds with videoStreamingCapability
--  which contains additionalVideoStreamingCapabilities array with incorrect parameters
--
-- Preconditions:
-- 1. HMICapabilitiesCacheFile is set in smartDeviceLink.ini
-- 2. SDL and HMI are started
--
-- Sequence:
-- 1. SDL requests UI.GetCapabilities()
--   HMI sends UI.GetCapabilities(videoStreamingCapability) response with additionalVideoStreamingCapabilities
--   which contains additionalVideoStreamingCapabilities array with incorrect parameters
-- SDL does:
-- - a. not cache the videoStreamingCapability with additionalVideoStreamingCapabilities
-- 2. It is restarted ignition cycle
-- SDL does:
-- - a. requests UI.GetCapabilities()
-- 3. App registers with 5 transport protocol
--   App requests GetSystemCapability(VIDEO_STREAMING)
-- SDL does:
-- - a. send GetSystemCapability response with videoStreamingCapability that contains
--    the additionalVideoStreamingCapabilities received from HMI in UI.GetCapabilities response in last ignition cycle
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/UpdateVideoStreamingCapabilities/common')

--[[ Local Variables ]]
local isSubscribe = false
local appSessionId = 1

local checks = { }

checks.invalid_type = common.getVideoStreamingCapability(1)
checks.invalid_type.additionalVideoStreamingCapabilities[1].supportedFormats[1].pixelPerInch = "264" -- invalid type

checks.invalid_value = common.getVideoStreamingCapability(2)
checks.invalid_value.additionalVideoStreamingCapabilities[1].preferredResolution.resolutionHeight = -2 -- invalid value

checks.invalid_nested_type = common.getVideoStreamingCapability(2)
checks.invalid_nested_type.additionalVideoStreamingCapabilities[2] = common.getVideoStreamingCapability(1)
checks.invalid_nested_type.additionalVideoStreamingCapabilities[2].additionalVideoStreamingCapabilities[1]
  .diagonalScreenSize = true -- invalid type

checks.invalid_nested_value = common.getVideoStreamingCapability(3)
checks.invalid_nested_value.additionalVideoStreamingCapabilities[2] = common.getVideoStreamingCapability(2)
checks.invalid_nested_value.additionalVideoStreamingCapabilities[2].additionalVideoStreamingCapabilities[2]
  .supportedFormats = "RTP" -- invalid value

--[[ Local Functions ]]
local function getHMIParamsWithUiRequestOnly()
  local vsc = common.cloneTable(common.anotherVideoStreamingCapabilityWithOutAddVSC)
  local params = common.getHMIParamsWithOutRequests()
  params.UI.GetCapabilities.occurrence = 1
  params.UI.GetCapabilities.params.systemCapabilities.videoStreamingCapability = vsc
  return params
end

--[[ Scenario ]]
for type, value in pairs(checks) do
  common.Title("Preconditions")
  common.Step("Clean environment", common.preconditions)
  common.Step("Update HMICapabilitiesCacheFile in SDL.ini file ", common.setSDLIniParameter,
    { "HMICapabilitiesCacheFile", "hmi_capabilities_cache.json" })
  common.Step("Set HMI Capabilities", common.setHMICapabilities, { value })
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { common.hmiDefaultCapabilities })

  common.Title("Test")
  common.Step("Ignition off", common.ignitionOff)
  common.Step("Ignition on, SDL sends HMI capabilities request to HMI for UI.GetCapabilities only",
    common.start, { getHMIParamsWithUiRequestOnly() })
  common.Step("RAI", common.registerAppWOPTU)
  common.Step("App sends GetSystemCapability for VIDEO_STREAMING " .. type, common.getSystemCapability,
    { isSubscribe, appSessionId, common.anotherVideoStreamingCapabilityWithOutAddVSC })

  common.Title("Postconditions")
  common.Step("Stop SDL", common.postconditions)
end
