-- https://adc.luxoft.com/jira/browse/FORDTCN-6977
-- [GetSystemCapability] Unsubscription from VIDEO_STREAMING system capability updates
---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0296-Update-video-streaming-capabilities-during-ignition-cycle.md
--
-- Description: Processing of OnSystemCapabilityUpdated notification with additionalVideoStreamingCapabilities parameter
--  in case App sends GetSystemCapability request with subscribe = false
--
-- Preconditions:
-- 1. SDL and HMI are started
-- 2. HMI sends UI.GetCapabilities(videoStreamingCapability) with additionalVideoStreamingCapabilities parameter
-- 3. App is subscribed to videoStreamingCapability
--
-- Sequence:
-- 1. HMI sends OnSystemCapabilityUpdated(params) notification without addVSC parameter to SDL
--  a. SDL sends OnSystemCapabilityUpdated(params) notification to App
-- 2. App sends GetSystemCapability request for "VIDEO_STREAMING" with subscribe = false  to SDL
--  a. SDL sends GetSystemCapability(videoStreamingCapability) response with additionalVideoStreamingCapabilities
--   received from HMI to App
-- 3. HMI sends OnSystemCapabilityUpdated(params) notification without addVSC parameter to SDL
--  a. SDL does not send OnSystemCapabilityUpdated(params) notification without addVSC parameter to App
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/UpdateVideoStreamingCapabilities/common')

--[[ Local Variables ]]
local expected = 1
local notExpected = 0

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Set HMI Capabilities", common.setHMICapabilities)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { common.hmiDefaultCapabilities })
common.Step("RAI", common.registerAppWOPTU)
common.Step("Activate App", common.activateApp)
common.Step("GetSystemCapability with subscribe = true", common.getSystemCapability, { true })
common.Step("OnSystemCapabilityUpdated", common.sendOnSystemCapabilityUpdated, { expected })

common.Title("Test")
common.Step("GetSystemCapability with subscribe = false", common.getSystemCapability, { false })
common.Step("OnSystemCapabilityUpdated", common.sendOnSystemCapabilityUpdated, { notExpected })


common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
