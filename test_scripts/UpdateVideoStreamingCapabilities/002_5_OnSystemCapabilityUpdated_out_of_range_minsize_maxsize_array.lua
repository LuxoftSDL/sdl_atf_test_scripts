-- https://adc.luxoft.com/jira/browse/FORDTCN-XXXX

---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/UpdateVideoStreamingCapabilities/common')

--[[ Local Variables ]]
local appSessionId = 1
local notExpected = 0
local isSubscribe = true
local arraySize = {
  minSize = 0,
  maxSize = 101
}

--[[ Scenario ]]
for parameter, value in pairs(arraySize) do
  common.Title("Preconditions")
  common.Step("Clean environment", common.preconditions)
  common.Step("Set HMI Capabilities", common.setHMICapabilities)
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { common.hmiDefaultCapabilities })
  common.Step("RAI", common.registerAppWOPTU)
  common.Step("Activate App", common.activateApp)
  common.Step("GetSystemCapability with subscribe = true", common.getSystemCapability, { isSubscribe })

  common.Title("Test")
  common.Step("OnSystemCapabilityUpdated out of range " .. parameter .. " " .. value,
    common.sendOnSystemCapabilityUpdated, { appSessionId, notExpected, common.getVideoStreamingCapability(value) })

  common.Title("Postconditions")
  common.Step("Stop SDL", common.postconditions)
end
