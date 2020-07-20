-- https://adc.luxoft.com/jira/browse/FORDTCN-6974

---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/UpdateVideoStreamingCapabilities/common')

--[[ Local Variables ]]
local isSubscribe = true

local vsc = common.cloneTable(common.anotherVideoStreamingCapabilityWithOutAddVSC)

local function sendOnSystemCapabilityUpdatedWithoutAppId()
  local systemCapabilityParam = {
    systemCapability = {
      systemCapabilityType = "VIDEO_STREAMING",
      videoStreamingCapability = vsc
    },
    appID = nil -- no app id
  }
  common.getHMIConnection():SendNotification("BasicCommunication.OnSystemCapabilityUpdated", systemCapabilityParam)
  common.getMobileSession():ExpectNotification("OnSystemCapabilityUpdated", systemCapabilityParam)
  :Times(0)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Set HMI Capabilities", common.setHMICapabilities)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { common.hmiDefaultCapabilities })
common.Step("RAI", common.registerAppWOPTU)
common.Step("Activate App", common.activateApp)
common.Step("GetSystemCapability with subscribe = true", common.getSystemCapability, { isSubscribe })

common.Title("Test")
common.Step("OnSystemCapabilityUpdated", sendOnSystemCapabilityUpdatedWithoutAppId)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
