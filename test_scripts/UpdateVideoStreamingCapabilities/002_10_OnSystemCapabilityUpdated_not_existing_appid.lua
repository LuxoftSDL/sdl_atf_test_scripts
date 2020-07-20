-- https://adc.luxoft.com/jira/browse/FORDTCN-XXXX

---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/UpdateVideoStreamingCapabilities/common')

--[[ Local Variables ]]
local appSessionId = 1
local isSubscribe = true

local vsc = common.cloneTable(common.anotherVideoStreamingCapabilityWithOutAddVSC)

local function sendOnSystemCapabilityUpdatedWithNotExistingAppId()
  local systemCapabilityParam = {
    systemCapability = {
      systemCapabilityType = "VIDEO_STREAMING",
      videoStreamingCapability = vsc
    },
    appID = common.getHMIAppId(appSessionId) + 1 -- not existing app id
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
common.Step("OnSystemCapabilityUpdated", sendOnSystemCapabilityUpdatedWithNotExistingAppId)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
