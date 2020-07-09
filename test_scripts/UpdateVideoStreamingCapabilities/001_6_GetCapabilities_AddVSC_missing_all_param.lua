-- https://adc.luxoft.com/jira/browse/FORDTCN-6960
-- [GetCapabilities] Transfering of additionalVideoStreamingCapabilities parameter from HMI to SDL – no parameters in single item in array
---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0296-Update-video-streaming-capabilities-during-ignition-cycle.md
--
-- Description: Processing of GetCapabilities in case no parameters in single item in array
-- of additionalVideoStreamingCapabilities parameter
--
-- Preconditions:
-- 1. SDL and HMI are started
-- 2. HMI sends UI.GetCapabilities(videoStreamingCapability) with empty single item in array
--  of additionalVideoStreamingCapabilities parameters
--
-- Sequence:
-- 1. App sends GetSystemCapability request for "VIDEO_STREAMING" to SDL
--  a. SDL sends GetSystemCapability response with default videoStreamingCapability value from hmi_capabilities.json
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/UpdateVideoStreamingCapabilities/common')

--[[ Local Variables ]]
local appSessionId = 1

local emptyAddVSC = common.getVideoStreamingCapability()
emptyAddVSC.additionalVideoStreamingCapabilities = {{ }}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Set HMI Capabilities", common.setHMICapabilities, { emptyAddVSC })
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { common.hmiDefaultCapabilities })
common.Step("RAI", common.registerAppWOPTU)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("App sends GetSystemCapability for VIDEO_STREAMING", common.getSystemCapability,
  { false, appSessionId, common.defaultVideoStreamingCapability })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
