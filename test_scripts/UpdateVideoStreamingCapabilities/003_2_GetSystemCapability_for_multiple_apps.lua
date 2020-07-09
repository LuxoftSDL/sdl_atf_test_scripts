---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0296-Update-video-streaming-capabilities-during-ignition-cycle.md
--
-- Description: Processing of OnSystemCapabilityUpdated with additionalVideoStreamingCapabilities parameter
--  for multiple Apps
--
-- Preconditions:
-- 1. SDL and HMI are started
-- 2. HMI sends UI.GetCapabilities(videoStreamingCapability) with additionalVideoStreamingCapabilities
-- 3. App1 and App2 are registered
--
-- Sequence:
-- 1. HMI sends OnSystemCapabilityUpdated(params) notification to SDL
--  a. SDL does not send OnSystemCapabilityUpdated(params) notification to App1 and App2
-- 2. App1 sends GetSystemCapability request for "VIDEO_STREAMING" with subscribe = true  to SDL
--  a. SDL sends GetSystemCapability(videoStreamingCapability) response with additionalVideoStreamingCapabilities
--   received from HMI to App
-- 3. HMI sends OnSystemCapabilityUpdated(params) notification to SDL
--  a. SDL sends OnSystemCapabilityUpdated(params) notification to App1 and does not send to App2
-- 4. App2 sends GetSystemCapability request for "VIDEO_STREAMING" with subscribe = true  to SDL
--  a. SDL sends GetSystemCapability(videoStreamingCapability) response with additionalVideoStreamingCapabilities
--   received from HMI to App
-- 5. HMI sends OnSystemCapabilityUpdated(params) notification to SDL
--  a. SDL sends OnSystemCapabilityUpdated(params) notification to App1 and  App2
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/UpdateVideoStreamingCapabilities/common')

--[[ Local Variables ]]
local appSessionId1 = 1
local appSessionId2 = 2
local expected = 1
local notExpected = 0

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Set HMI Capabilities", common.setHMICapabilities)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { common.hmiDefaultCapabilities })
common.Step("Register App1", common.registerAppWOPTU, { appSessionId1 })
common.Step("Register App2", common.registerAppWOPTU, { appSessionId2 })

common.Title("Test")
common.Step("OnSystemCapabilityUpdated",
  common.sendOnSystemCapabilityUpdatedMultipleApps, { notExpected, notExpected })
common.Step("App1 sends GetSystemCapability with subscribe = true",
  common.getSystemCapability, { true, appSessionId1 })
common.Step("OnSystemCapabilityUpdated to App1",
  common.sendOnSystemCapabilityUpdatedMultipleApps, { expected, notExpected })
common.Step("App2 sends GetSystemCapability with subscribe = true",
  common.getSystemCapability, { true, appSessionId2 })
common.Step("Sends OnSystemCapabilityUpdated to App1 and App2",
  common.sendOnSystemCapabilityUpdatedMultipleApps, { expected, expected })
common.Step("App1 sends GetSystemCapability with subscribe = false",
  common.getSystemCapability, { false, appSessionId2 })
common.Step("OnSystemCapabilityUpdated to App2",
  common.sendOnSystemCapabilityUpdatedMultipleApps, { notExpected, expected })
common.Step("App2 sends GetSystemCapability with subscribe = false",
  common.getSystemCapability, { false, appSessionId2 })
common.Step("OnSystemCapabilityUpdated",
  common.sendOnSystemCapabilityUpdatedMultipleApps, { notExpected, notExpected })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
