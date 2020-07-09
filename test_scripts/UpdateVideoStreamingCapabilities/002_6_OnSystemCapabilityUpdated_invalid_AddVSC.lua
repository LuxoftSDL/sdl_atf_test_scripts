---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0296-Update-video-streaming-capabilities-during-ignition-cycle.md
--
-- Description: Processing of OnSystemCapabilityUpdated with invalid value of additionalVideoStreamingCapabilities parameter
--
-- Preconditions:
-- 1. SDL and HMI are started
-- 2. HMI sends UI.GetCapabilities(videoStreamingCapability) with invalid value
--  of additionalVideoStreamingCapabilities parameters
-- 3. App is subscribed to videoStreamingCapability
--
-- Sequence:
-- 1. HMI sends OnSystemCapabilityUpdated(params) notification with invalid value of addVSC to SDL
--  a. HMI does not send OnSystemCapabilityUpdated(params) notification to SDL
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/UpdateVideoStreamingCapabilities/common')

--[[ Local Variables ]]
local expected = 1
local notExpected = 0

local invalidAddVSC = common.videoStreamingCapabilityWithOutAddVSC
invalidAddVSC.additionalVideoStreamingCapabilities = {{
  preferredResolution = {
    resolutionWidth = 8000,
    resolutionHeight = 8000
  },
  maxBitrate = 50000,
  supportedFormats = {{
    protocol = "RTSP",
    codec = "invalidCodec" -- invalid value
  }},
  hapticSpatialDataSupported = false,
  diagonalScreenSize = 500,
  pixelPerInch = 250,
  scale = 2
}}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("RAI", common.registerAppWOPTU)
common.Step("Activate App", common.activateApp)
common.Step("GetSystemCapability with subscribe = true", common.getSystemCapability, { true })
common.Step("OnSystemCapabilityUpdated", common.sendOnSystemCapabilityUpdated, { expected })

common.Title("Test")
common.Step("GetSystemCapability with subscribe = false", common.getSystemCapability, { false })
common.Step("OnSystemCapabilityUpdated", common.sendOnSystemCapabilityUpdated, { notExpected, invalidAddVSC })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
