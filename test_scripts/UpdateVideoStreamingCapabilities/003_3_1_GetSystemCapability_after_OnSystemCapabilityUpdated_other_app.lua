-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0296-Update-video-streaming-capabilities-during-ignition-cycle.md
--
-- Description:  SDL successfully transfers received from HMI on startup videoStreamingCapabilities
--  to the application after updates of them for other application
--
-- Preconditions:
-- 1. SDL and HMI are started
-- 2. SDL received videoStreamingCapabilities from HMI
-- 3. Application 1 is registered and activated
-- 4. Application 1 is subscribed on OnSystemCapabilityUpdated notification with VIDEO_STREAMING capability type
--
-- Sequence:
-- 1. HMI sends OnSystemCapabilityUpdated notification with updates of VIDEO_STREAMING capability type for Application 1
-- SDL does:
-- - a. resend OnSystemCapabilityUpdated notification with updates of VIDEO_STREAMING capability type
--    to the Application 1
-- 2. Application 2 is registered and requests videoStreamingCapabilities via GetSystemCapability RPC
-- SDL does:
-- - a. send response to the Aplication 2 with received from HMI on startup videoStreamingCapabilities
--    which stored internally
-- - b. not request videoStreamingCapabilities from HMI
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/UpdateVideoStreamingCapabilities/common')

--[[ Local Variables ]]
local appSessionId1 = 1
local appSessionId2 = 2
local expected = 1

local vsc = common.getVideoStreamingCapability(5)
vsc.additionalVideoStreamingCapabilities[1].preferredResolution = { resolutionWidth = 1920, resolutionHeight = 1080 }
vsc.additionalVideoStreamingCapabilities[2].preferredResolution = { resolutionWidth = 1024, resolutionHeight = 768 }
vsc.additionalVideoStreamingCapabilities[5].preferredResolution = { resolutionWidth = 15, resolutionHeight = 2 }

local function getSystemCapability(pAppId)
  local requestParams = {
    systemCapabilityType = "VIDEO_STREAMING"
  }
  local responseParams = {
    success = true,
    resultCode = "SUCCESS",
    systemCapability = {
      systemCapabilityType = "VIDEO_STREAMING",
      videoStreamingCapability = common.getVideoStreamingCapability()
    }
  }
  local corId = common.getMobileSession(pAppId):SendRPC("GetSystemCapability", requestParams)
  common.getHMIConnection():ExpectRequest("UI.GetCapabilities"):Times(0)
  common.getMobileSession(pAppId):ExpectResponse(corId, responseParams)
  :ValidIf(function(_, data)
    if not common.isTableEqual(responseParams, data.payload) then
      return false, "Parameters of the response are incorrect: \nExpected: " .. common.toString(responseParams)
      .. "\nActual: " .. common.toString(data.payload)
    end
    return true
  end)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Set HMI Capabilities", common.setHMICapabilities)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { common.hmiDefaultCapabilities })
common.Step("Register App 1", common.registerAppWOPTU)
common.Step("GetSystemCapability with subscribe = true", common.getSystemCapability, { true })

common.Title("Test")
common.Step("OnSystemCapabilityUpdated", common.sendOnSystemCapabilityUpdated, { appSessionId1, expected, vsc })
common.Step("GetSystemCapability", getSystemCapability, { appSessionId1 })
common.Step("Register App 2", common.registerAppWOPTU, { appSessionId2 })
common.Step("Activate App 2", common.activateApp, { appSessionId2 })
common.Step("GetSystemCapability", getSystemCapability, { appSessionId2 })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
