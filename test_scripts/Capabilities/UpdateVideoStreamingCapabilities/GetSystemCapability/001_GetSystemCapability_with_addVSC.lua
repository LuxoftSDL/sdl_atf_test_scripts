-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0296-Update-video-streaming-capabilities-during-ignition-cycle.md
--
-- Description: SDL successfully transfers videoStreamingCapabilities with additionalVideoStreamingCapabilities
--  to the Application via GetSystemCapability RPC
--
-- Preconditions:
-- 1. SDL and HMI are started
-- 2. SDL received videoStreamingCapabilities from HMI
-- 3. App is registered and activated
--
-- Sequence:
-- 1. App requests videoStreamingCapabilities via GetSystemCapability RPC
-- SDL does:
-- - a. send response to the App with videoStreamingCapabilities with additionalVideoStreamingCapabilities
--    stored internally
-- - b. not request videoStreamingCapabilities from HMI
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/UpdateVideoStreamingCapabilities/common')

--[[ Local Variables ]]
local vsc = common.getVideoStreamingCapability(5)
vsc.additionalVideoStreamingCapabilities[1].preferredResolution = { resolutionWidth = 1920, resolutionHeight = 1080 }
vsc.additionalVideoStreamingCapabilities[3].preferredResolution = { resolutionWidth = 1024, resolutionHeight = 768 }
vsc.additionalVideoStreamingCapabilities[4].preferredResolution = { resolutionWidth = 15, resolutionHeight = 2 }

--[[ Local Functions ]]
local function getSystemCapability()
  local requestParams = {
    systemCapabilityType = "VIDEO_STREAMING"
  }
  local responseParams = {
    success = true,
    resultCode = "SUCCESS",
    systemCapability = {
      systemCapabilityType = "VIDEO_STREAMING",
      videoStreamingCapability = vsc
    }
  }
  local corId = common.getMobileSession():SendRPC("GetSystemCapability", requestParams)
  common.getHMIConnection():ExpectRequest("UI.GetCapabilities"):Times(0)
  common.getMobileSession():ExpectResponse(corId, responseParams)
  :ValidIf(function(_, data)
      if not common.isTableEqual(responseParams, data.payload) then
        return false, "Parameters of the notification are incorrect: \nExpected: " .. common.toString(responseParams)
          .. "\nActual: " .. common.toString(data.payload)
      end
      return true
    end)
  end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Set HMI Capabilities", common.setHMICapabilities, { vsc })
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { common.hmiDefaultCapabilities })
common.Step("Register App", common.registerAppWOPTU)

common.Title("Test")
common.Step("Check GetSystemCapability processing", getSystemCapability)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
