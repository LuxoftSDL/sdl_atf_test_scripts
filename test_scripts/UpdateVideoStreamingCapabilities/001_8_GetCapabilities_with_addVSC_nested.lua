-- https://adc.luxoft.com/jira/browse/FORDTCN-6964

---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/UpdateVideoStreamingCapabilities/common')

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
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("App sends GetSystemCapability for VIDEO_STREAMING", common.getSystemCapability,
  { false, 1, vsc })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
