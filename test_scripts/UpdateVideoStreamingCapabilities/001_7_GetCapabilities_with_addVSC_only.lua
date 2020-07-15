-- https://adc.luxoft.com/jira/browse/FORDTCN-7006

---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/UpdateVideoStreamingCapabilities/common')

local vsc = {
    additionalVideoStreamingCapabilities = {}
}
vsc.additionalVideoStreamingCapabilities = common.anotherVideoStreamingCapabilityWithOutAddVSC

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
