-- https://adc.luxoft.com/jira/browse/FORDTCN-XXXX
---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0296-Update-video-streaming-capabilities-during-ignition-cycle.md
--
-- Description: Processing of OnSystemCapabilityUpdated notification with not existing appID
--
-- Preconditions:
-- 1. Default HMI capabilities contain data about videoStreamingCapability 
-- 2. SDL and HMI are started
-- 3. App is registered without PTU, activated and subscribed on SystemCapabilities
--
-- Sequence:
-- 1. HMI sends OnSystemCapabilityUpdated notification for "VIDEO_STREAMING" to SDL 
-- with not existing appID
--  a. SDL doesn't send OnSystemCapabilityUpdated (videoStreamingCapability) notification to mobile 
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
