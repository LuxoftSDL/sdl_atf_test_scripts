---------------------------------------------------------------------------------------------------
-- Common module for VideoStreamingCapability
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local runner = require('user_modules/script_runner')
local hmi_values = require('user_modules/hmi_values')
local SDL = require('SDL')
local json = require("modules/json")
local utils = require("user_modules/utils")

--[[ General configuration parameters ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 5
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 7
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 0

--[[ Shared Functions ]]
local m = {}
m.Title = runner.Title
m.Step = runner.Step
m.preconditions = actions.preconditions
m.start = actions.start
m.postconditions = actions.postconditions
m.registerAppWOPTU = actions.registerAppWOPTU
m.activateApp = actions.activateApp
m.cloneTable = utils.cloneTable
m.hmiDefaultCapabilities = hmi_values.getDefaultHMITable()
m.EMPTY_ARRAY = json.EMPTY_ARRAY
m.getPreloadedPT = actions.sdl.getPreloadedPT
m.setPreloadedPT = actions.sdl.setPreloadedPT

--[[ Common Variables ]]
local defaultSDLcapabilities = SDL.HMICap.get()
m.defaultVideoStreamingCapability = defaultSDLcapabilities.UI.systemCapabilities.videoStreamingCapability

--[[ Common Functions ]]
m.videoStreamingCapabilityWithOutAddVSC = {
  preferredResolution = {
    resolutionWidth = 5000,
    resolutionHeight = 5000
  },
  maxBitrate = 1073741823,
  supportedFormats = {{
    protocol = "RTP",
    codec = "VP9"
  }},
  hapticSpatialDataSupported = true,
  diagonalScreenSize = 1000,
  pixelPerInch = 500,
  scale = 5.5
}

m.anotherVideoStreamingCapabilityWithOutAddVSC = {
  preferredResolution = {
    resolutionWidth = 200,
    resolutionHeight = 200
  },
  maxBitrate = 200,
  supportedFormats = {{
    protocol = "WEBM",
    codec = "H265"
  }},
  hapticSpatialDataSupported = false,
  diagonalScreenSize = 200,
  pixelPerInch = 200,
  scale = 3
}

function m.getVideoStreamingCapability(pArraySizeAddVSC)
  if not pArraySizeAddVSC then pArraySizeAddVSC = 1 end
  local vSC = utils.cloneTable(m.videoStreamingCapabilityWithOutAddVSC)
  vSC.additionalVideoStreamingCapabilities = {}
  if pArraySizeAddVSC == 0 then
    vSC.additionalVideoStreamingCapabilities = utils.cloneTable(m.videoStreamingCapabilityWithOutAddVSC)
  else
    for i = 1, pArraySizeAddVSC do
      vSC.additionalVideoStreamingCapabilities[i] = utils.cloneTable(m.videoStreamingCapabilityWithOutAddVSC)
    end
  end
  return vSC
end

function m.getAnotherVideoStreamingCapability(pArraySizeAddVSC)
  if not pArraySizeAddVSC then pArraySizeAddVSC = 1 end
  local vSC = utils.cloneTable(m.anotherVideoStreamingCapabilityWithOutAddVSC)
  vSC.additionalVideoStreamingCapabilities = {}
  if pArraySizeAddVSC == 0 then
    vSC.additionalVideoStreamingCapabilities = utils.cloneTable(m.anotherVideoStreamingCapabilityWithOutAddVSC)
  else
    for i = 1, pArraySizeAddVSC do
      vSC.additionalVideoStreamingCapabilities[i] = utils.cloneTable(m.anotherVideoStreamingCapabilityWithOutAddVSC)
    end
  end
  return vSC
end

function m.setHMICapabilities(pVSC)
  if not pVSC then pVSC = m.getVideoStreamingCapability() end
  m.hmiDefaultCapabilities.UI.GetCapabilities.params.systemCapabilities.videoStreamingCapability = pVSC
end

function m.getSystemCapability(pSubscribe, pAppId, pResponseParams)
  if not pAppId then pAppId = 1 end
  if not pResponseParams then pResponseParams = m.getVideoStreamingCapability() end
  local requestParams = {
    systemCapabilityType = "VIDEO_STREAMING",
    subscribe = pSubscribe
  }
  local corId = actions.getMobileSession(pAppId):SendRPC("GetSystemCapability", requestParams)
  actions.getMobileSession(pAppId):ExpectResponse(corId, { success = true, resultCode = "SUCCESS",
    systemCapability = {
      systemCapabilityType = "VIDEO_STREAMING",
      videoStreamingCapability = pResponseParams
    }
  })
end

function m.sendOnSystemCapabilityUpdated(pTimes, pParams)
  if not pTimes then pTimes = 1 end
  if not pParams then pParams = m.getVideoStreamingCapability() end
  local systemCapabilityParam = {
    systemCapability = {
      systemCapabilityType = "VIDEO_STREAMING",
      videoStreamingCapability = pParams
    }
  }
  actions.getHMIConnection():SendNotification("BasicCommunication.OnSystemCapabilityUpdated", systemCapabilityParam)
  actions.getMobileSession():ExpectNotification("OnSystemCapabilityUpdated", systemCapabilityParam)
  :Times(pTimes)
end

function m.sendOnSystemCapabilityUpdatedMultipleApps(pTimesAppId1, pTimesAppId2, pParams)
  if not pParams then pParams = m.getVideoStreamingCapability() end
  local systemCapabilityParam = {
    systemCapability = {
      systemCapabilityType = "VIDEO_STREAMING",
      videoStreamingCapability = pParams
    }
  }
  --systemCapabilityParam.appID = actions.getHMIAppId()
  actions.getHMIConnection():SendNotification("BasicCommunication.OnSystemCapabilityUpdated", systemCapabilityParam)
  actions.getMobileSession(1):ExpectNotification("OnSystemCapabilityUpdated", systemCapabilityParam)
  :Times(pTimesAppId1)
  actions.getMobileSession(2):ExpectNotification("OnSystemCapabilityUpdated", systemCapabilityParam)
  :Times(pTimesAppId2)
end

local function getAppConfig(pPt)
  local out = utils.cloneTable(pPt.policy_table.app_policies.default)
    out.groups = { "Base-4" }
    out.AppHMIType = { "NAVIGATION" }
    return out
end

function m.preparePreloadedPT()
  local preloadedTable = m.getPreloadedPT()
  local appId = config["application1"].registerAppInterfaceParams.fullAppID
  preloadedTable.policy_table.app_policies[appId] = getAppConfig(preloadedTable)
  preloadedTable.policy_table.functional_groupings["DataConsent-2"].rpcs = utils.json.null
  m.setPreloadedPT(preloadedTable)
end

function m.sendOnAppCapabilityUpdated(appCapability, pTimesOnHMI)
  if not appCapability then appCapability = {
    appCapability = {
      appCapabilityType = "VIDEO_STREAMING",
      videoStreamingCapability = m.getVideoStreamingCapability()
    }
  } end
  actions.getMobileSession(1):SendNotification("OnAppCapabilityUpdated", appCapability)
  actions.getHMIConnection():ExpectNotification("BasicCommunication.OnAppCapabilityUpdated", appCapability)
  :Times(pTimesOnHMI)
end

return m
