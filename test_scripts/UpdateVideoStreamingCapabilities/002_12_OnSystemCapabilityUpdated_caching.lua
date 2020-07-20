-- https://adc.luxoft.com/jira/browse/FORDTCN-6984

---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/UpdateVideoStreamingCapabilities/common')

--[[ Local Variables ]]
local appSessionId = 1
local expected = 1
local isSubscribe = true

local vsc = common.cloneTable(common.anotherVideoStreamingCapabilityWithOutAddVSC)

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Update HMICapabilitiesCacheFile in SDL.ini file ", common.setSDLIniParameter,
  { "HMICapabilitiesCacheFile", "hmi_capabilities_cache.json" })
common.Step("Set HMI Capabilities", common.setHMICapabilities)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { common.hmiDefaultCapabilities })
common.Step("RAI", common.registerAppWOPTU)
common.Step("Activate App", common.activateApp)
common.Step("GetSystemCapability with subscribe = true", common.getSystemCapability, { isSubscribe })

common.Title("Test")
common.Step("OnSystemCapabilityUpdated", common.sendOnSystemCapabilityUpdated,
  { appSessionId, expected, vsc })
common.Step("Ignition off", common.ignitionOff)
common.Step("Ignition on, SDL doesn't send HMI capabilities requests to HMI",
  common.start, { common.getHMIParamsWithOutRequests() })
common.Step("RAI", common.registerAppWOPTU)
common.Step("Activate App", common.activateApp)
common.Step("GetSystemCapability to check stored capabilities", common.getSystemCapability)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
