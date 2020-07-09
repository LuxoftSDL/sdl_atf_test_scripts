-- https://adc.luxoft.com/jira/browse/FORDTCN-6980
-- [OnSystemCapabilityUpdated] Transfering of updates of videoStreamingCapabilities from HMI to mobile – no parameters
---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0296-Update-video-streaming-capabilities-during-ignition-cycle.md
--
-- Description: Processing of OnSystemCapabilityUpdated notification in case all parameters are missed
--
-- Preconditions:
-- 1. SDL and HMI are started
-- 2. HMI sends UI.GetCapabilities(videoStreamingCapability) with additionalVideoStreamingCapabilities parameter
--
-- Sequence:
-- 1. HMI sends OnSystemCapabilityUpdated(params) notification without any parameters to SDL
--  a. SDL does not send OnSystemCapabilityUpdated(params) notification to App
-- 2. App sends GetSystemCapability request for "VIDEO_STREAMING" with subscribe = true  to SDL
--  a. SDL sends GetSystemCapability(videoStreamingCapability) response with additionalVideoStreamingCapabilities
--   received from HMI to App
-- 3. HMI sends OnSystemCapabilityUpdated(params) notification without any parameters to SDL
--  a. SDL does not send OnSystemCapabilityUpdated(params) notification to App
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/UpdateVideoStreamingCapabilities/common')

--[[ Local Variables ]]
local notExpected = 0
local misingAllVSCparam = {}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Set HMI Capabilities", common.setHMICapabilities)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { common.hmiDefaultCapabilities })
common.Step("RAI", common.registerAppWOPTU)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("OnSystemCapabilityUpdated", common.sendOnSystemCapabilityUpdated,
  { notExpected, misingAllVSCparam })
common.Step("GetSystemCapability with subscribe = true", common.getSystemCapability, { true })
common.Step("OnSystemCapabilityUpdated", common.sendOnSystemCapabilityUpdated,
  { notExpected, misingAllVSCparam })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
