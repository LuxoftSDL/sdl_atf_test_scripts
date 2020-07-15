-- https://adc.luxoft.com/jira/browse/FORDTCN-6960

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
