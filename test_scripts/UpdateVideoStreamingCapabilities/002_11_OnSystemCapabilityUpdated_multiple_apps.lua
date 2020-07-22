---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0296-Update-video-streaming-capabilities-during-ignition-cycle.md
--
-- Description: Processing of OnSystemCapabilityUpdated notification for 2 applications at once
--
-- Preconditions:
-- 1. HMI capabilities contain data about videoStreamingCapability
-- 2. SDL and HMI are started
-- 3. App1 and App2 are registered and activated
--
-- Sequence:
-- 1. HMI sends OnSystemCapabilityUpdated notification for "VIDEO_STREAMING" to SDL
-- SDL does:
--  a. not send OnSystemCapabilityUpdated (videoStreamingCapability) notification to App1 and App2
-- 2. App1 subscribes on videoStreamingCapability updates
--   HMI sends OnSystemCapabilityUpdated notification for "VIDEO_STREAMING" to SDL
-- SDL does:
--  a. send OnSystemCapabilityUpdated (videoStreamingCapability) notification to App1
--    and doesn't send notification to App2
-- 3. App2 subscribes on videoStreamingCapability updates
--   HMI sends OnSystemCapabilityUpdated notification for "VIDEO_STREAMING" to SDL
-- SDL does:
--  a. send OnSystemCapabilityUpdated (videoStreamingCapability) notification to each apps
-- 4. App1 unsubscribes from videoStreamingCapability updates
--   HMI sends OnSystemCapabilityUpdated notification for "VIDEO_STREAMING" to SDL
-- SDL does:
--  a. send OnSystemCapabilityUpdated (videoStreamingCapability) notification to App2
--    and doesn't send notification to App1
-- 5. App2 unsubscribes from videoStreamingCapability updates
--   HMI sends OnSystemCapabilityUpdated notification for "VIDEO_STREAMING" to SDL
-- SDL does:
--  a. not send OnSystemCapabilityUpdated (videoStreamingCapability) notification to each apps
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/UpdateVideoStreamingCapabilities/common')

--[[ Local Variables ]]
local appSessionIdAbsent = nil
local appSessionId1 = 1
local appSessionId2 = 2
local expected = 1
local notExpected = 0
local isSubscribe = true
local isUnSubscribe = false

--[[ Local Functions ]]
local function sendOnSystemCapabilityUpdatedMultipleApps(pAppId, pTimesAppId1, pTimesAppId2)
  local mobileParams = {
    systemCapability = {
      systemCapabilityType = "VIDEO_STREAMING",
      videoStreamingCapability = common.getVideoStreamingCapability()
    }
  }
  local hmiParams = common.cloneTable(mobileParams)
  if pAppId then
    hmiParams.appID = common.getHMIAppId(pAppId)
  end
  common.getHMIConnection():SendNotification("BasicCommunication.OnSystemCapabilityUpdated", hmiParams)
  common.getMobileSession(1):ExpectNotification("OnSystemCapabilityUpdated", mobileParams)
  :Times(pTimesAppId1)
  :ValidIf(function(_, data)
    if pTimesAppId1 == 1 and (not common.isTableEqual(mobileParams, data.payload)) then
      return false, "Parameters of the notification received by App1 are incorrect: \nExpected: "
        .. common.toString(mobileParams) .. "\nActual: " .. common.toString(data.payload)
    end
    return true
  end)
  common.getMobileSession(2):ExpectNotification("OnSystemCapabilityUpdated", mobileParams)
  :Times(pTimesAppId2)
  :ValidIf(function(_, data)
    if pTimesAppId2 == 1 and (not common.isTableEqual(mobileParams, data.payload)) then
      return false, "Parameters of the notification received by App2 are incorrect: \nExpected: "
        .. common.toString(mobileParams) .. "\nActual: " .. common.toString(data.payload)
    end
    return true
  end)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Set HMI Capabilities", common.setHMICapabilities)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { common.hmiDefaultCapabilities })
common.Step("Register App1", common.registerAppWOPTU, { appSessionId1 })
common.Step("Register App2", common.registerAppWOPTU, { appSessionId2 })

common.Title("Test")
common.Step("OnSystemCapabilityUpdated appID = 1",
  sendOnSystemCapabilityUpdatedMultipleApps, { appSessionId1, notExpected, notExpected })
common.Step("OnSystemCapabilityUpdated appID = 2",
  sendOnSystemCapabilityUpdatedMultipleApps, { appSessionId2, notExpected, notExpected })
common.Step("OnSystemCapabilityUpdated no appID",
  sendOnSystemCapabilityUpdatedMultipleApps, { appSessionIdAbsent, notExpected, notExpected })

common.Step("App1 sends GetSystemCapability with subscribe = true",
  common.getSystemCapability, { isSubscribe, appSessionId1 })
common.Step("OnSystemCapabilityUpdated appID = 1",
  sendOnSystemCapabilityUpdatedMultipleApps, { appSessionId1, expected, notExpected })
common.Step("OnSystemCapabilityUpdated appID = 2",
  sendOnSystemCapabilityUpdatedMultipleApps, { appSessionId2, notExpected, notExpected })
common.Step("OnSystemCapabilityUpdated no appID",
  sendOnSystemCapabilityUpdatedMultipleApps, { appSessionIdAbsent, notExpected, notExpected })

common.Step("App2 sends GetSystemCapability with subscribe = true",
  common.getSystemCapability, { isSubscribe, appSessionId2 })
common.Step("OnSystemCapabilityUpdated appID = 1",
  sendOnSystemCapabilityUpdatedMultipleApps, { appSessionId1, expected, notExpected })
common.Step("OnSystemCapabilityUpdated appID = 2",
  sendOnSystemCapabilityUpdatedMultipleApps, { appSessionId2, notExpected, expected })
common.Step("OnSystemCapabilityUpdated no appID",
  sendOnSystemCapabilityUpdatedMultipleApps, { appSessionIdAbsent, notExpected, notExpected })

common.Step("App1 sends GetSystemCapability with subscribe = false",
  common.getSystemCapability, { isUnSubscribe, appSessionId1 })
common.Step("OnSystemCapabilityUpdated appID = 1",
  sendOnSystemCapabilityUpdatedMultipleApps, { appSessionId1, notExpected, notExpected })
common.Step("OnSystemCapabilityUpdated appID = 2",
  sendOnSystemCapabilityUpdatedMultipleApps, { appSessionId2, notExpected, expected })
common.Step("OnSystemCapabilityUpdated no appID",
  sendOnSystemCapabilityUpdatedMultipleApps, { appSessionIdAbsent, notExpected, notExpected })

common.Step("App2 sends GetSystemCapability with subscribe = false",
  common.getSystemCapability, { isUnSubscribe, appSessionId2 })
common.Step("OnSystemCapabilityUpdated appID = 1",
  sendOnSystemCapabilityUpdatedMultipleApps, { appSessionId1, notExpected, notExpected })
common.Step("OnSystemCapabilityUpdated appID = 2",
  sendOnSystemCapabilityUpdatedMultipleApps, { appSessionId2, notExpected, notExpected })
common.Step("OnSystemCapabilityUpdated no appID",
  sendOnSystemCapabilityUpdatedMultipleApps, { appSessionIdAbsent, notExpected, notExpected })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
