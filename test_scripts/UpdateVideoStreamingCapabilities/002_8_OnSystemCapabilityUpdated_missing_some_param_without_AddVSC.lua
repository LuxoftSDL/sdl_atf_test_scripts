-- https://adc.luxoft.com/jira/browse/FORDTCN-6979
-- [OnSystemCapabilityUpdated] Transfering of updates of videoStreamingCapabilities from HMI to mobile – not all parameters
---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0296-Update-video-streaming-capabilities-during-ignition-cycle.md
--
-- Description: Processing of OnSystemCapabilityUpdated notification without
--  non-mandatory additionalVideoStreamingCapabilities parameter in case some parameter is missed
--
-- Preconditions:
-- 1. SDL and HMI are started
-- 2. HMI sends UI.GetCapabilities(videoStreamingCapability) with additionalVideoStreamingCapabilities parameter
--
-- Sequence:
-- 1. HMI sends OnSystemCapabilityUpdated(params) notification without preferredResolution parameter to SDL
--  a. SDL does not send OnSystemCapabilityUpdated(params) notification to App
-- 2. App sends GetSystemCapability request for "VIDEO_STREAMING" with subscribe = true  to SDL
--  a. SDL sends GetSystemCapability(videoStreamingCapability) response with additionalVideoStreamingCapabilities
--   received from HMI to App
-- 3. HMI sends OnSystemCapabilityUpdated(params) notification without preferredResolution parameter to SDL
--  a. SDL sends OnSystemCapabilityUpdated(params) notification without addVSC parameter to App
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/UpdateVideoStreamingCapabilities/common')

--[[ Local Variables ]]
local notExpected = 0
local videoStreamingCapabilityWithOutAddVSC = {
  -- preferredResolution = { -- is missing
  --   resolutionWidth = 5000,
  --   resolutionHeight = 5000
  -- },
  maxBitrate = 1073741823,
  supportedFormats = {{
    protocol = "RTP",
    codec = "VP9"
  }},
  hapticSpatialDataSupported = true,
  diagonalScreenSize = 1000,
  pixelPerInch = 500,
  scale = 5.5
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Set HMI Capabilities", common.setHMICapabilities)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { common.hmiDefaultCapabilities })
common.Step("RAI", common.registerAppWOPTU)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("OnSystemCapabilityUpdated", common.sendOnSystemCapabilityUpdated,
  { notExpected, videoStreamingCapabilityWithOutAddVSC })
common.Step("GetSystemCapability with subscribe = true", common.getSystemCapability, { true })
common.Step("OnSystemCapabilityUpdated", common.sendOnSystemCapabilityUpdated,
  { notExpected, videoStreamingCapabilityWithOutAddVSC })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
