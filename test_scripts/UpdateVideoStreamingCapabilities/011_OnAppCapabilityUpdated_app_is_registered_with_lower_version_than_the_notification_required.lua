---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0296-Update-video-streaming-capabilities-during-ignition-cycle.md
--
-- Description:
-- Processing OnAppCapabilityUpdated notification from mobile to HMI
--
-- Precondition:
-- 1. SDL and HMI are started
-- 2. App1 with NAVIGATION appHMIType is registered with version 6.0
-- 3. OnAppCapabilityUpdated notification is alowed by policy for App1
--
-- Sequence:
-- 1. App1 sends OnAppCapabilityUpdated for VIDEO_STREAMING capability type
-- 2. SDL doesn't send OnAppCapabilityUpdated notification to the HMI

---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/UpdateVideoStreamingCapabilities/common')

config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 6
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 0

local appCapability = {
  appCapability = {
    appCapabilityType = "VIDEO_STREAMING",
    videoStreamingCapability = common.getVideoStreamingCapability()
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
common.Step("App sends OnAppCapabilityUpdated for VIDEO_STREAMING", common.sendOnAppCapabilityUpdated, 
	{ appCapability, 0 } )

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
