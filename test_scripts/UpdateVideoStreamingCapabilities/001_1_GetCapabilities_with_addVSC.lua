-- https://adc.luxoft.com/jira/browse/FORDTCN-6958
-- [GetCapabilities] Transfering of additionalVideoStreamingCapabilities parameter from HMI to SDL – happy path
---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0296-Update-video-streaming-capabilities-during-ignition-cycle.md
--
-- Description: Processing of GetCapabilities with additionalVideoStreamingCapabilities parameter
--
-- Preconditions:
-- 1. SDL and HMI are started
-- 2. HMI sends UI.GetCapabilities(videoStreamingCapability) with additionalVideoStreamingCapabilities
--
-- Sequence:
-- 1. App sends GetSystemCapability request for "VIDEO_STREAMING" to SDL
--  a. SDL sends GetSystemCapability(videoStreamingCapability) response with additionalVideoStreamingCapabilities
--   received from HMI to App
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/UpdateVideoStreamingCapabilities/common')

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Set HMI Capabilities", common.setHMICapabilities)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { common.hmiDefaultCapabilities })
common.Step("RAI", common.registerAppWOPTU)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("App sends GetSystemCapability for VIDEO_STREAMING", common.getSystemCapability)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
