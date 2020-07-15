-- https://adc.luxoft.com/jira/browse/FORDTCN-6966

---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/UpdateVideoStreamingCapabilities/common')

--[[ Local Variables ]]
local appSessionId = 1

local checks = { }

checks.invalid_type = common.getVideoStreamingCapability(1)
checks.invalid_type.additionalVideoStreamingCapabilities[1].preferredResolution.resolutionWidth = true -- invalid type

checks.invalid_value = common.getVideoStreamingCapability(2)
checks.invalid_value.additionalVideoStreamingCapabilities[1].supportedFormats[1].codec = "H266" -- invalid value

checks.invalid_nested_type = common.getVideoStreamingCapability(2)
checks.invalid_nested_type.additionalVideoStreamingCapabilities[2] = common.getVideoStreamingCapability(1)
checks.invalid_nested_type.additionalVideoStreamingCapabilities[2].additionalVideoStreamingCapabilities[1].hapticSpatialDataSupported = 18 -- invalid type

checks.invalid_nested_value = common.getVideoStreamingCapability(3)
checks.invalid_nested_value.additionalVideoStreamingCapabilities[2] = common.getVideoStreamingCapability(2)
checks.invalid_nested_value.additionalVideoStreamingCapabilities[2].additionalVideoStreamingCapabilities[2].scale = -1 -- invalid value

checks.invalid_deep_nested_type = common.getVideoStreamingCapability(1)
checks.invalid_deep_nested_type.additionalVideoStreamingCapabilities[1] = common.getVideoStreamingCapability(3)
checks.invalid_deep_nested_type.additionalVideoStreamingCapabilities[1].additionalVideoStreamingCapabilities[2] = common.getVideoStreamingCapability(2)
checks.invalid_deep_nested_type.additionalVideoStreamingCapabilities[1].additionalVideoStreamingCapabilities[2].additionalVideoStreamingCapabilities[2].supportedFormats = 2 -- invalid type

checks.invalid_deep_nested_value = common.getVideoStreamingCapability(3)
checks.invalid_deep_nested_value.additionalVideoStreamingCapabilities[2] = common.getVideoStreamingCapability(1)
checks.invalid_deep_nested_value.additionalVideoStreamingCapabilities[3] = common.getVideoStreamingCapability(5)
checks.invalid_deep_nested_value.additionalVideoStreamingCapabilities[3].additionalVideoStreamingCapabilities[2] = common.getVideoStreamingCapability(1)
checks.invalid_deep_nested_value.additionalVideoStreamingCapabilities[3].additionalVideoStreamingCapabilities[2].additionalVideoStreamingCapabilities[1] = common.getVideoStreamingCapability(3)
checks.invalid_deep_nested_value.additionalVideoStreamingCapabilities[3].additionalVideoStreamingCapabilities[2].additionalVideoStreamingCapabilities[1].additionalVideoStreamingCapabilities[1] = common.getVideoStreamingCapability(2)
checks.invalid_deep_nested_value.additionalVideoStreamingCapabilities[3].additionalVideoStreamingCapabilities[2].additionalVideoStreamingCapabilities[1].additionalVideoStreamingCapabilities[1].additionalVideoStreamingCapabilities[2].pixelPerInch = -2 -- invalid value

--[[ Scenario ]]
for type, value in pairs(checks) do
  common.Title("Preconditions")
  common.Step("Clean environment", common.preconditions)
  common.Step("Set HMI Capabilities", common.setHMICapabilities, { value })
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { common.hmiDefaultCapabilities })
  common.Step("RAI", common.registerAppWOPTU)
  common.Step("Activate App", common.activateApp)

  common.Title("Test")
  common.Step("App sends GetSystemCapability for VIDEO_STREAMING " .. type, common.getSystemCapability,
    { false, appSessionId, common.defaultVideoStreamingCapability })

  common.Title("Postconditions")
  common.Step("Stop SDL", common.postconditions)
end
