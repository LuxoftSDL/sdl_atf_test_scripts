-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0296-Update-video-streaming-capabilities-during-ignition-cycle.md
--
-- Description: SDL applies the videoStreamingCapability with additionalVideoStreamingCapabilities received from HMI
--  in UI.GetCapabilities response in case additionalVideoStreamingCapabilities parameter contains
--  nested additionalVideoStreamingCapabilities parameter
--
-- Preconditions:
-- 1. SDL and HMI are started

-- Sequence:
-- 1. SDL requests UI.GetCapabilities()
-- 2. HMI sends UI.GetCapabilities(videoStreamingCapability) response with additionalVideoStreamingCapabilities
--  and additionalVideoStreamingCapabilities parameter contains nested additionalVideoStreamingCapabilities parameter
-- SDL does:
-- - a. apply the videoStreamingCapability with additionalVideoStreamingCapabilities internally
-- 3. App registers with 5 transport protocol
-- 4. App requests GetSystemCapability(VIDEO_STREAMING)
-- SDL does:
-- - a. send GetSystemCapability response with videoStreamingCapability that contains
--    the additionalVideoStreamingCapabilities received from HMI in UI.GetCapabilities response
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/UpdateVideoStreamingCapabilities/common')

--[[ Local Variables ]]
local appSessionId = 1
local isSubscribe = false

local vsc = common.getVideoStreamingCapability(10)
vsc.additionalVideoStreamingCapabilities[8] = common.getVideoStreamingCapability(1)
vsc.additionalVideoStreamingCapabilities[6] = common.getVideoStreamingCapability(4)
vsc.additionalVideoStreamingCapabilities[5] = common.getVideoStreamingCapability(2)
vsc.additionalVideoStreamingCapabilities[10] = common.getVideoStreamingCapability(2)

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Set HMI Capabilities", common.setHMICapabilities, { vsc })
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { common.hmiDefaultCapabilities })
common.Step("RAI", common.registerAppWOPTU)

common.Title("Test")
common.Step("App sends GetSystemCapability for VIDEO_STREAMING", common.getSystemCapability,
  { isSubscribe, appSessionId, vsc })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
