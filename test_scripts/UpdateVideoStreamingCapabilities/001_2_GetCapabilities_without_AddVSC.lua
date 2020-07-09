-- https://adc.luxoft.com/jira/browse/FORDTCN-7007
-- [GetCapabilities] Transfering of videoStreamingCapabilities parameter without additionalVideoStreamingCapabilities from HMI to SDL
---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0296-Update-video-streaming-capabilities-during-ignition-cycle.md
--
-- Description: Processing of GetCapabilities without non-mandatory additionalVideoStreamingCapabilities parameter
--
-- Preconditions:
-- 1. SDL and HMI are started
-- 2. HMI sends UI.GetCapabilities(videoStreamingCapability) without non-mandatory additionalVideoStreamingCapabilities
--
-- Sequence:
-- 1. App sends GetSystemCapability request for "VIDEO_STREAMING" to SDL
--  a. SDL sends GetSystemCapability(videoStreamingCapability) response without non-mandatory
--   additionalVideoStreamingCapabilities received from HMI to App
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/UpdateVideoStreamingCapabilities/common')

--[[ Local Variables ]]
local appSessionId = 1

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Set HMI Capabilities", common.setHMICapabilities)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { common.hmiDefaultCapabilities })
common.Step("RAI", common.registerAppWOPTU)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("App sends GetSystemCapability for VIDEO_STREAMING", common.getSystemCapability,
  { false, appSessionId, common.getVideoStreamingCapability() })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
