---------------------------------------------------------------------------------------------------
-- Common module for VideoStreamingCapability
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local runner = require('user_modules/script_runner')
local hmi_values = require('user_modules/hmi_values')
local SDL = require('SDL')
local events = require('events')
local json = require("modules/json")
local utils = require("user_modules/utils")
local constants = require('protocol_handler/ford_protocol_constants')
local bson = require("bson4lua")

--[[ General configuration parameters ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 5
config.ValidateSchema = false
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 7
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 0
constants.FRAME_SIZE.P5 = 131084

--[[ Shared Functions ]]
local m = {}
m.Title = runner.Title
m.Step = runner.Step
m.start = actions.start
m.postconditions = actions.postconditions
m.registerAppWOPTU = actions.registerAppWOPTU
m.activateApp = actions.activateApp
m.getHMIAppId = actions.app.getHMIId
m.getHMIConnection = actions.hmi.getConnection
m.getMobileSession = actions.mobile.getSession
m.setSDLIniParameter = actions.sdl.setSDLIniParameter
m.cloneTable = utils.cloneTable
m.toString = utils.toString
m.isTableEqual = utils.isTableEqual
m.hmiDefaultCapabilities = hmi_values.getDefaultHMITable()
m.EMPTY_ARRAY = json.EMPTY_ARRAY
m.getPreloadedPT = actions.sdl.getPreloadedPT
m.setPreloadedPT = actions.sdl.setPreloadedPT
m.spairs = utils.spairs
m.policyTableUpdate = actions.policyTableUpdate
m.registerApp = actions.registerApp
m.preconditions = actions.preconditions

--[[ Common Variables ]]
m.hmiDefaultCapabilities = hmi_values.getDefaultHMITable()
local defaultSDLcapabilities = SDL.HMICap.get()
m.defaultVideoStreamingCapability = defaultSDLcapabilities.UI.systemCapabilities.videoStreamingCapability

local bsonType = {
  DOUBLE   = 0x01,
  STRING   = 0x02,
  DOCUMENT = 0x03,
  ARRAY    = 0x04,
  BOOLEAN  = 0x08,
  INT32    = 0x10,
  INT64    = 0x12
}

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

function m.setHMICapabilities(pVSC)
  if not pVSC then pVSC = m.getVideoStreamingCapability() end
  m.hmiDefaultCapabilities.UI.GetCapabilities.params.systemCapabilities.videoStreamingCapability = pVSC
end

function m.sendOnSystemCapabilityUpdated(pAppId, pTimes, pParams )
  if not pTimes then pTimes = 1 end
  if not pParams then pParams = m.getVideoStreamingCapability() end
  local mobileParams = {
    systemCapability = {
      systemCapabilityType = "VIDEO_STREAMING",
      videoStreamingCapability = pParams
    }
  }
  local hmiParams = m.cloneTable(mobileParams)
  hmiParams.appID = m.getHMIAppId(pAppId)
  actions.getHMIConnection():SendNotification("BasicCommunication.OnSystemCapabilityUpdated", hmiParams)
  actions.getMobileSession():ExpectNotification("OnSystemCapabilityUpdated", mobileParams)
  :Times(pTimes)
  :ValidIf(function(_, data)
      if not utils.isTableEqual(mobileParams, data.payload) then
        return false, "Parameters of the notification are incorrect: \nExpected: " .. utils.toString(mobileParams)
          .. "\nActual: " .. utils.toString(data.payload)
      end
      return true
    end)
end

function m.getHMIParamsWithOutRequests(pParams)
  local params = pParams or utils.cloneTable(m.hmiDefaultCapabilities)
  params.RC.GetCapabilities.occurrence = 0
  params.UI.GetSupportedLanguages.occurrence = 0
  params.UI.GetCapabilities.occurrence = 0
  params.VR.GetSupportedLanguages.occurrence = 0
  params.VR.GetCapabilities.occurrence = 0
  params.TTS.GetSupportedLanguages.occurrence = 0
  params.TTS.GetCapabilities.occurrence = 0
  params.Buttons.GetCapabilities.occurrence = 0
  params.VehicleInfo.GetVehicleType.occurrence = 0
  params.UI.GetLanguage.occurrence = 0
  params.VR.GetLanguage.occurrence = 0
  params.TTS.GetLanguage.occurrence = 0
  return params
end

function m.ignitionOff()
  local hmiConnection = actions.hmi.getConnection()
  local mobileConnection = actions.mobile.getConnection()
  config.ExitOnCrash = false
  local timeout = 5000
  local function removeSessions()
    for i = 1, actions.mobile.getAppsCount() do
      actions.mobile.deleteSession(i)
    end
  end
  local event = events.Event()
  event.matches = function(event1, event2) return event1 == event2 end
  mobileConnection:ExpectEvent(event, "SDL shutdown")
  :Do(function()
    removeSessions()
    StopSDL()
    config.ExitOnCrash = true
  end)
  hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  hmiConnection:ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
    hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",{ reason = "IGNITION_OFF" })
    for i = 1, actions.mobile.getAppsCount() do
      actions.mobile.getSession(i):ExpectNotification("OnAppInterfaceUnregistered", { reason = "IGNITION_OFF" })
    end
  end)
  hmiConnection:ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
  :Times(actions.mobile.getAppsCount())
  local isSDLShutDownSuccessfully = false
  hmiConnection:ExpectNotification("BasicCommunication.OnSDLClose")
  :Do(function()
    utils.cprint(35, "SDL was shutdown successfully")
    isSDLShutDownSuccessfully = true
    mobileConnection:RaiseEvent(event, event)
  end)
  :Timeout(timeout)
  local function forceStopSDL()
    if isSDLShutDownSuccessfully == false then
      utils.cprint(35, "SDL was shutdown forcibly")
      mobileConnection:RaiseEvent(event, event)
    end
  end
  actions.run.runAfter(forceStopSDL, timeout + 500)
end

function m.sendOnAppCapabilityUpdated(appCapability, pTimesOnHMI, pAppId)
  if not pAppId then pAppId = 1 end
  if not pTimesOnHMI then pTimesOnHMI = 1 end
  local uiGetCapabilities = m.hmiDefaultCapabilities.UI.GetCapabilities.params
  if not appCapability then appCapability = {
      appCapability = {
        appCapabilityType = "VIDEO_STREAMING",
        videoStreamingCapability = uiGetCapabilities.systemCapabilities.videoStreamingCapability
      }
    }
  end
  actions.getMobileSession(pAppId):SendNotification("OnAppCapabilityUpdated", appCapability)
  actions.getHMIConnection():ExpectNotification("BasicCommunication.OnAppCapabilityUpdated", appCapability)
  :Times(pTimesOnHMI)
end

local function getVideoDataForStartServicePayload(pData)
  local out = {
    height = pData.preferredResolution.resolutionHeight,
    width = pData.preferredResolution.resolutionWidth,
    videoProtocol = pData.supportedFormats[1].protocol,
    videoCodec = pData.supportedFormats[1].codec
  }
  return out
end

function m.startVideoService(pData, pAppId, isEncryption)
  if not pAppId then pAppId = 1 end
  if isEncryption == nil then isEncryption = false end

  local videoData = getVideoDataForStartServicePayload(pData)

  local videoPayload = {
    height          = { type = bsonType.INT32,  value = videoData.height },
    width           = { type = bsonType.INT32,  value = videoData.width },
    videoProtocol   = { type = bsonType.STRING, value = videoData.videoProtocol },
    videoCodec      = { type = bsonType.STRING, value = videoData.videoCodec },
  }

  local msg = {
      serviceType = constants.SERVICE_TYPE.VIDEO,
      frameInfo = constants.FRAME_INFO.START_SERVICE,
      encryption = isEncryption,
      frameType = constants.FRAME_TYPE.CONTROL_FRAME,
      binaryData = bson.to_bytes(videoPayload)
    }
  actions.getMobileSession(pAppId):Send(msg)

  actions.getHMIConnection():ExpectRequest("Navigation.SetVideoConfig",{
    config = {
      height = videoData.height,
      width = videoData.width,
      protocol = videoData.videoProtocol,
      codec = videoData.videoCodec
    }
  })
  :Do(function(_, data)
      actions.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  actions.getHMIConnection(pAppId):ExpectRequest("Navigation.StartStream")
  :Do(function(_, data)
      actions.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
end

function m.startVideoStreaming(pAppId)
  if not pAppId then pAppId = 1 end
  actions.getMobileSession(pAppId):StartStreaming(11, "files/SampleVideo_5mb.mp4")
  actions.getHMIConnection():ExpectNotification("Navigation.OnVideoDataStreaming", { available = true })
  utils.cprint(33, "Streaming...")
  utils.wait(1000)
end

function m.stopVideoStreaming(pAppId)
  actions.getMobileSession(pAppId):StopStreaming("files/SampleVideo_5mb.mp4")
  actions.getHMIConnection():ExpectNotification("Navigation.OnVideoDataStreaming", { available = false })
end

function m.stopVideoService(pAppId)
  actions.getMobileSession(pAppId):StopService(11)
  actions.getHMIConnection(pAppId):ExpectRequest("Navigation.StopStream")
  :Do(function(_, data)
      actions.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
end

return m
