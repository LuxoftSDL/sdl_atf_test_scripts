---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0296-Update-video-streaming-capabilities-during-ignition-cycle.md
--
-- Description: Resolution switching from mobile app after receiving OnSystemCapabilityUpdated notification
--  with new video capabilities during secure video streaming
--
-- Preconditions:
-- 1. SDL and HMI are started
-- 2. App is registered and activated with 5 transport protocol
-- 3. HMI sends UI.GetCapabilities(videoStreamingCapability) with additionalVideoStreamingCapabilities
-- 4. App is subscribed to video streaming capabilities update
-- 5. App sent supported video capabilities using OnAppCapabilityUpdated notification to HMI
-- 6. Video service is started, handshake is performed during service start
-- 7. App starts video streaming
--
-- Sequence:
-- 1. HMI sends OnSystemCapabilityUpdated with new video capabilities
-- SDL does:
--  a. send OnSystemCapabilityUpdated notification to App with received parameters
-- 2. App stops streaming and video service by sending EndService(VIDEO) to SDL
-- SDL does:
--  a. send Navi.OnVideoDataStreaming(available=false) to HMI
--  b. respond with EndServiceACK(VIDEO) to Mobile App
--  c. request Navi.StopStream
-- 3. App restarts video service with new video parameters and sends StartService(VIDEO, new_video_params) to SDL
--  SDL does:
--  a. handshake is not started
--  b. request Navi.SetVideoConfig(new_video_params)
-- 4. HMI responds with SUCCESS resultCode to Navi.SetVideoConfig(new_video_params)
-- SDL does:
--  a. send StartService(VIDEO, new_video_params) to App
-- 5. Mobile app starts streaming with new video params
-- SDL does:
--  a. request Navi.StopStream
--  b. send Navi.OnVideoDataStreaming(available=false) to HMI after successful response to Navi.StopStream from HMI
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/UpdateVideoStreamingCapabilities/common')

--[[ General configuration parameters ]]
config.SecurityProtocol = "DTLS"
config.application1.registerAppInterfaceParams.appName = "server"
config.application1.registerAppInterfaceParams.fullAppID = "SPT"

--[[ Local Variables ]]
local isSubscribed = true
local expected = 1
local notExpected = 0
local appSessionId = 1

local videoCapSupportedByApp = {
  appCapability = {
    appCapabilityType = "VIDEO_STREAMING",
    videoStreamingCapability = common.getVideoStreamingCapability(3)
  }
}

local videoCapSupportedByHMI = common.getVideoStreamingCapability(5)

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.securePreconditions)
common.Step("Set HMI Capabilities", common.setHMICapabilities, { videoCapSupportedByHMI })

common.Step("Start SDL, HMI, connect Mobile, start Session", common.startWithGetSystemTime,
  { common.hmiDefaultCapabilities })
common.Step("Register App", common.registerAppWOPTU)
common.Step("Activate App", common.activateApp)
common.Step("App sends GetSystemCapability for VIDEO_STREAMING", common.getSystemCapability,
  { isSubscribed, appSessionId, videoCapSupportedByHMI })
common.Step("OnAppCapabilityUpdated with supported video capabilities", common.sendOnAppCapabilityUpdated,
  { videoCapSupportedByApp })
common.Step("Start secure video service", common.startSecureVideoService,
  { common.videoStreamingCapabilityWithOutAddVSC, expected})
common.Step("Start video streaming", common.startVideoStreaming)

common.Title("Test")
common.Step("OnSystemCapabilityUpdated with new video params", common.sendOnSystemCapabilityUpdated,
  {appSessionId, expected, common.anotherVideoStreamingCapabilityWithOutAddVSC })
common.Step("Stop video streaming", common.stopVideoStreaming)
common.Step("Stop video service", common.stopVideoService)
common.Step("Start secure video service with new parameters", common.startSecureVideoService,
  { common.anotherVideoStreamingCapabilityWithOutAddVSC, notExpected })
common.Step("Start video streaming with new parameters", common.startVideoStreaming)

common.Title("Postconditions")
common.Step("Stop SDL", common.securePostconditions)
