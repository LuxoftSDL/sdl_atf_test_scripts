---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that the SDL takes default parameters from hmi_capabilities.json in case
-- HMI does not send one of GetCapabilities/GetLanguage/GetVehicleType response due to timeout

-- Preconditions:
-- 1. hmi_capabilities_cache.json file doesn't exist on file system
-- 2. HMI and SDL are started
-- Sequence:
-- 1. HMI does not provide any Capability
--  a. use default capability from hmi_capabilities.json file
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')
config.application1.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }

--[[ Local Variables ]]
local hmiDefaultCap = common.getDefaultHMITable()
local hmiCapabilities = common.updatedHMICapabilitiesTable()

local requests = {
  UI = { "GetCapabilities" },
  RC = { "GetCapabilities" }
}

local systemCapabilities = {
  UI = {
    NAVIGATION = { navigationCapability = hmiCapabilities.UI.systemCapabilities.navigationCapability },
    PHONE_CALL = { phoneCapability = hmiCapabilities.UI.systemCapabilities.phoneCapability },
    VIDEO_STREAMING = { videoStreamingCapability = hmiCapabilities.UI.systemCapabilities.videoStreamingCapability }},
  RC = {
    REMOTE_CONTROL = { remoteControlCapability = hmiCapabilities.RC.remoteControlCapability },
    SEAT_LOCATION = { seatLocationCapability = hmiCapabilities.RC.seatLocationCapability }
  }
}

--[[ Local Functions ]]
local function updateHMICaps(pMod, pRequest)
  for key,_ in pairs (hmiDefaultCap) do
    if key == pMod then
      hmiDefaultCap[pMod][pRequest] = nil
      if not pMod == "Buttons" then
        hmiDefaultCap[pMod].IsReady.params.available = true
      end
    end
  end
end

--[[ Scenario ]]
for mod, req  in pairs(requests) do
  for _, pReq  in ipairs(req) do
common.Title("TC processing " .. tostring(mod) .."]")
common.Title("Preconditions")
common.Step("Back-up/update PPT", common.updatePreloadedPT)
common.Step("Clean environment", common.preconditions)
common.Step("Update HMI capabilities", common.updatedHMICapabilitiesFile)

common.Title("Test")

common.Step("Updated default HMI Capabilities", updateHMICaps, { mod, pReq })
common.Step("Ignition on, Start SDL, HMI", common.start, { hmiDefaultCap })
common.Step("App registration", common.registerApp)
common.Step("App activation", common.activateApp)
  for sysCapType, cap  in pairs(systemCapabilities[mod]) do
    common.Step("getSystemCapability "..sysCapType, common.getSystemCapability, { sysCapType, cap })
  end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
  end
end

