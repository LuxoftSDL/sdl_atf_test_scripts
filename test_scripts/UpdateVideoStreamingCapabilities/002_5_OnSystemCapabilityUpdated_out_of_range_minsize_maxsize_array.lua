-- https://adc.luxoft.com/jira/browse/FORDTCN-XXXX
---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0296-Update-video-streaming-capabilities-during-ignition-cycle.md
--
-- Description: Processing of OnSystemCapabilityUpdated notification with invalid 
-- number of additionalVideoStreamingCapabilities array items
--
-- Preconditions:
-- 1. Default HMI capabilities contain data about videoStreamingCapability 
-- 2. SDL and HMI are started
-- 3. App is registered without PTU, activated and subscribed on SystemCapabilities
--
-- Sequence:
-- 1. HMI sends OnSystemCapabilityUpdated notification for "VIDEO_STREAMING" to SDL with invalid 
-- number of additionalVideoStreamingCapabilities array items
--  a. SDL sends OnSystemCapabilityUpdated (videoStreamingCapability) notification to mobile 
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/UpdateVideoStreamingCapabilities/common')

--[[ Local Variables ]]
local appSessionId = 1
local notExpected = 0
local isSubscribe = true
local arraySize = {
  minSize = 0,
  maxSize = 101
}

--[[ Scenario ]]
for parameter, value in pairs(arraySize) do
  common.Title("Preconditions")
  common.Step("Clean environment", common.preconditions)
  common.Step("Set HMI Capabilities", common.setHMICapabilities)
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { common.hmiDefaultCapabilities })
  common.Step("RAI", common.registerAppWOPTU)
  common.Step("Activate App", common.activateApp)
  common.Step("GetSystemCapability with subscribe = true", common.getSystemCapability, { isSubscribe })

  common.Title("Test")
  common.Step("OnSystemCapabilityUpdated out of range " .. parameter .. " " .. value,
    common.sendOnSystemCapabilityUpdated, { appSessionId, notExpected, common.getVideoStreamingCapability(value) })

  common.Title("Postconditions")
  common.Step("Stop SDL", common.postconditions)
end
