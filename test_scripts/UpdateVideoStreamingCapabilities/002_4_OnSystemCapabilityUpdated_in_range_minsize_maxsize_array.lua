---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0296-Update-video-streaming-capabilities-during-ignition-cycle.md
--
-- Description: Processing of OnSystemCapabilityUpdated notification with the minsize and maxsize for an array
--  of additionalVideoStreamingCapabilities parameter
--
-- Preconditions:
-- 1. SDL and HMI are started
-- 2. HMI sends UI.GetCapabilities(videoStreamingCapability) with additionalVideoStreamingCapabilities parameter
-- 3. App is subscribed to videoStreamingCapability
--
-- Sequence:
-- 1. HMI sends OnSystemCapabilityUpdated(params) notification to SDL
--  a. SDL sends OnSystemCapabilityUpdated(params) notification to App
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/UpdateVideoStreamingCapabilities/common')

--[[ Local Variables ]]
local expected = 1
local arraySize = {
  minSize = 1,
  maxSize = 100
}

--[[ Scenario ]]
for parameter, value in pairs(arraySize) do
  common.Title("Preconditions")
  common.Step("Clean environment", common.preconditions)
  common.Step("Set HMI Capabilities", common.setHMICapabilities)
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { common.hmiDefaultCapabilities })
  common.Step("RAI", common.registerAppWOPTU)
  common.Step("Activate App", common.activateApp)
  common.Step("GetSystemCapability with subscribe = true", common.getSystemCapability, { true })
  common.Step("OnSystemCapabilityUpdated", common.sendOnSystemCapabilityUpdated, { expected })

  common.Title("Test")
  common.Step("OnSystemCapabilityUpdated in range " .. parameter .. " " .. value,
    common.sendOnSystemCapabilityUpdated, { expected, common.getVideoStreamingCapability(value) })

  common.Title("Postconditions")
  common.Step("Stop SDL", common.postconditions)
end
