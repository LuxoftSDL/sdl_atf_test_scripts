---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0296-Update-video-streaming-capabilities-during-ignition-cycle.md
--
-- Description:
-- Processing OnAppCapabilityUpdated notification from mobile to HMI
--
-- Precondition:
-- 1. SDL and HMI are started
-- 2. App1 with NAVIGATION appHMIType is registered
-- 3. OnAppCapabilityUpdated notification is alowed by policy for App1
--
-- Sequence:
-- 1. App1 sends OnAppCapabilityUpdated for VIDEO_STREAMING capability type with videoStreamingCapability 
--    parameter that contains additionalVideoStreamingCapabilities parameter only
-- 2. SDL sends OnAppCapabilityUpdated notification to the HMI

---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/UpdateVideoStreamingCapabilities/common')

local appCapability = {
  appCapability = {
  	appCapabilityType = "VIDEO_STREAMING",
    videoStreamingCapability = {
      additionalVideoStreamingCapabilities = {
        preferredResolution = {
          resolutionWidth = 5000,
          resolutionHeight = 5000
        },
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
    }
  }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Prepare preloaded policy table", common.preparePreloadedPT)
common.Step("Set HMI Capabilities", common.setHMICapabilities)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { common.hmiDefaultCapabilities })
common.Step("RAI", common.registerAppWOPTU)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("App sends OnAppCapabilityUpdated with additionalVideoStreamingCapabilities parameter only", 
  common.sendOnAppCapabilityUpdated, { appCapability, 1 } )

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
