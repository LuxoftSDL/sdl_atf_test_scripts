-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0296-Update-video-streaming-capabilities-during-ignition-cycle.md
--
-- Description: SDL applies the videoStreamingCapability with only additionalVideoStreamingCapabilities parameter
--  received from HMI in UI.GetCapabilities response
--
-- Preconditions:
-- 1. SDL and HMI are started

-- Sequence:
-- 1. SDL requests UI.GetCapabilities()
-- 2. HMI sends UI.GetCapabilities(videoStreamingCapability) response with only additionalVideoStreamingCapabilities
--  parameter
-- SDL does:
-- - a. apply the videoStreamingCapability with only additionalVideoStreamingCapabilities parameter internally
-- 3. App registers with 5 transport protocol
-- 4. App requests GetSystemCapability(VIDEO_STREAMING)
-- SDL does:
-- - a. send GetSystemCapability response with videoStreamingCapability that contains
--    only additionalVideoStreamingCapabilities received from HMI in UI.GetCapabilities response
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/UpdateVideoStreamingCapabilities/common')

local vsc = {
    additionalVideoStreamingCapabilities = {}
}
vsc.additionalVideoStreamingCapabilities[1] = common.anotherVideoStreamingCapabilityWithOutAddVSC

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Set HMI Capabilities", common.setHMICapabilities, { vsc })
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { common.hmiDefaultCapabilities })
common.Step("RAI", common.registerAppWOPTU)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("App sends GetSystemCapability for VIDEO_STREAMING", common.getSystemCapability,
  { false, 1, vsc })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
