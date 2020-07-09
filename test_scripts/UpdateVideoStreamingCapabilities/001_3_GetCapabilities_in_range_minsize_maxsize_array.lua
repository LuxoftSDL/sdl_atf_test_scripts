-- https://adc.luxoft.com/jira/browse/FORDTCN-7004
-- [GetCapabilities] Transfering of additionalVideoStreamingCapabilities parameter from HMI to SDL – count of items of array in range
-- https://adc.luxoft.com/jira/browse/FORDTCN-6963
-- [GetCapabilities] Transfering of additionalVideoStreamingCapabilities parameter from HMI to SDL – max count of items in array
---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0296-Update-video-streaming-capabilities-during-ignition-cycle.md
--
-- Description: Processing of GetCapabilities with the minsize and maxsize for an array
--  of additionalVideoStreamingCapabilities parameter
--
-- Preconditions:
-- 1. SDL and HMI are started
-- 2. HMI sends UI.GetCapabilities(videoStreamingCapability) with (the minsize/maxsize for an array)
--  of additionalVideoStreamingCapabilities
--
-- Sequence:
-- 1. App sends GetSystemCapability request for "VIDEO_STREAMING" to SDL
--  a. SDL sends GetSystemCapability(videoStreamingCapability) response with additionalVideoStreamingCapabilities
--   received from HMI to App
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/UpdateVideoStreamingCapabilities/common')

--[[ Local Variables ]]
local appSessionId = 1
local arraySize = {
  minSize = 1,
  maxSize = 100
}

--[[ Scenario ]]
for parameter, value in pairs(arraySize) do
  common.Title("Preconditions")
  common.Step("Clean environment", common.preconditions)
  common.Step("Set HMI Capabilities", common.setHMICapabilities, { common.getVideoStreamingCapability(value) })
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { common.hmiDefaultCapabilities })
  common.Step("RAI", common.registerAppWOPTU)
  common.Step("Activate App", common.activateApp)

  common.Title("Test")
  common.Step("GetSystemCapability in range " .. parameter .. " " .. value, common.getSystemCapability,
    { false, appSessionId, common.getVideoStreamingCapability(value) })

  common.Title("Postconditions")
  common.Step("Stop SDL", common.postconditions)
end
