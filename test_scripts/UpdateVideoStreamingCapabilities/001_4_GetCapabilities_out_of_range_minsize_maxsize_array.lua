-- https://adc.luxoft.com/jira/browse/FORDTCN-7005

---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/UpdateVideoStreamingCapabilities/common')

--[[ Local Variables ]]
local appSessionId = 1
local arraySize = {
  minSize = 0,
  maxSize = 101
}

--[[ Scenario ]]
for parameter, value in pairs(arraySize) do
  common.Title("Preconditions")
  common.Step("Clean environment", common.preconditions)
  common.Step("Set HMI Capabilities", common.setHMICapabilities, { common.getVideoStreamingCapability(value) })
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { common.hmiDefaultCapabilities })
  common.Step("RAI", common.registerAppWOPTU)
  common.Step("Activate App", common.activateApp)

  common.Title("Test")
  common.Step("GetSystemCapability out of range " .. parameter .. " " .. value, common.getSystemCapability,
    { false, appSessionId, common.defaultVideoStreamingCapability })

  common.Title("Postconditions")
  common.Step("Stop SDL", common.postconditions)
end
