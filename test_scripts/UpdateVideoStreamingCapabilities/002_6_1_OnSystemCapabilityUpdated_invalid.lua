---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0296-Update-video-streaming-capabilities-during-ignition-cycle.md
--
-- Description: Processing of OnSystemCapabilityUpdated notification with invalid params
--
-- Preconditions:
-- 1. HMI capabilities contain data about videoStreamingCapability
-- 2. SDL and HMI are started
-- 3. App is registered, activated and subscribed on videoStreamingCapability updates
--
-- Sequence:
-- 1. HMI sends OnSystemCapabilityUpdated notification for "VIDEO_STREAMING" to SDL with invalid
-- values of VideoStreamingCapabilities parameters
-- SDL does:
--  a. not send OnSystemCapabilityUpdated (videoStreamingCapability) notification to mobile
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/UpdateVideoStreamingCapabilities/common')

--[[ Local Variables ]]
local appSessionId = 1
local notExpected = 0
local isSubscribe = true

local checks = { }

checks.invalid_type = common.cloneTable(common.anotherVideoStreamingCapabilityWithOutAddVSC)
checks.invalid_type.preferredResolution.resolutionWidth = "8000"  -- invalid type

checks.invalid_value = common.cloneTable(common.anotherVideoStreamingCapabilityWithOutAddVSC)
checks.invalid_value.maxBitrate = -1 -- invalid value

checks.invalid_additional_type = common.cloneTable(common.anotherVideoStreamingCapabilityWithOutAddVSC)
checks.invalid_additional_type.additionalVideoStreamingCapabilities = {
  [1] = common.cloneTable(common.videoStreamingCapabilityWithOutAddVSC),
  [2] = common.cloneTable(common.anotherVideoStreamingCapabilityWithOutAddVSC)
}
checks.invalid_additional_type.additionalVideoStreamingCapabilities[2].hapticSpatialDataSupported = 18 -- invalid type

checks.invalid_additional_value = common.cloneTable(common.anotherVideoStreamingCapabilityWithOutAddVSC)
checks.invalid_additional_value.additionalVideoStreamingCapabilities = {
  [1] = common.cloneTable(common.videoStreamingCapabilityWithOutAddVSC),
  [2] = common.cloneTable(common.anotherVideoStreamingCapabilityWithOutAddVSC)
}
checks.invalid_additional_value.additionalVideoStreamingCapabilities[1].scale = -1 -- invalid value

checks.invalid_deep_nested_type = common.cloneTable(common.anotherVideoStreamingCapabilityWithOutAddVSC)
checks.invalid_deep_nested_type.additionalVideoStreamingCapabilities = {
  [1] = common.getVideoStreamingCapability(2)
}

checks.invalid_deep_nested_type.additionalVideoStreamingCapabilities[1].additionalVideoStreamingCapabilities[1] =
  common.getVideoStreamingCapability(3)
checks.invalid_deep_nested_type.additionalVideoStreamingCapabilities[1].additionalVideoStreamingCapabilities[1]
  .additionalVideoStreamingCapabilities[3].supportedFormats = 2 -- invalid type

checks.invalid_deep_nested_value = common.cloneTable(common.anotherVideoStreamingCapabilityWithOutAddVSC)
checks.invalid_deep_nested_value.additionalVideoStreamingCapabilities = {
  [1] = common.getVideoStreamingCapability(3)
}
checks.invalid_deep_nested_value.additionalVideoStreamingCapabilities[1].additionalVideoStreamingCapabilities[2]
  .pixelPerInch = -2 -- invalid value

--[[ Scenario ]]
for type, value in pairs(checks) do
  common.Title("Preconditions")
  common.Step("Clean environment", common.preconditions)
  common.Step("Set HMI Capabilities", common.setHMICapabilities)
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { common.hmiDefaultCapabilities })
  common.Step("RAI", common.registerAppWOPTU)
  common.Step("Activate App", common.activateApp)
  common.Step("GetSystemCapability with subscribe = true", common.getSystemCapability, { isSubscribe })

  common.Title("Test")
  common.Step("OnSystemCapabilityUpdated " .. type, common.sendOnSystemCapabilityUpdated,
    {appSessionId, notExpected, value })

  common.Title("Postconditions")
  common.Step("Stop SDL", common.postconditions)
end
