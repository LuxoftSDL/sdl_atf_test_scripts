-- https://adc.luxoft.com/jira/browse/FORDTCN-6972
-- [GetCapabilities] Caching of additionalVideoStreamingCapabilities parameter – incorrect parameter is not cached
---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0296-Update-video-streaming-capabilities-during-ignition-cycle.md
--
-- Description: Processing of GetCapabilities with invalid value of additionalVideoStreamingCapabilities parameter
--
-- Preconditions:
-- 1. SDL and HMI are started
-- 2. HMI sends UI.GetCapabilities(videoStreamingCapability) with invalid value
--  of additionalVideoStreamingCapabilities parameters
--
-- Sequence:
-- 1. App sends GetSystemCapability request for "VIDEO_STREAMING" to SDL
--  a. SDL sends GetSystemCapability response with default videoStreamingCapability value from hmi_capabilities.json
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/UpdateVideoStreamingCapabilities/common')

--[[ Local Variables ]]
local appSessionId = 1

local invalidAddVSC = common.getVideoStreamingCapability()
invalidAddVSC.additionalVideoStreamingCapabilities = {{
  preferredResolution = {
    resolutionWidth = true, -- invalid type
    resolutionHeight = 8000
  },
  maxBitrate = 50000,
  supportedFormats = {{
    protocol = "RTSP",
    codec = "Theora"
  }},
  hapticSpatialDataSupported = false,
  diagonalScreenSize = 500,
  pixelPerInch = 250,
  scale = 2
}}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Set HMI Capabilities", common.setHMICapabilities, { invalidAddVSC })
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { common.hmiDefaultCapabilities })
common.Step("RAI", common.registerAppWOPTU)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("App sends GetSystemCapability for VIDEO_STREAMING", common.getSystemCapability,
  { false, appSessionId, common.defaultVideoStreamingCapability })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
