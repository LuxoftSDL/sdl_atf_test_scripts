-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0296-Update-video-streaming-capabilities-during-ignition-cycle.md
--
-- Description: SDL successfully unsubscribes an application from OnSystemCapabilityUpdated notification
--  with VIDEO_STREAMING capability type
--
-- Preconditions:
-- 1. SDL and HMI are started
-- 2. SDL received videoStreamingCapabilities from HMI
-- 3. Application is registered and activated
-- 4. Application is subscribed on OnSystemCapabilityUpdated notification with VIDEO_STREAMING capability type
--
-- Sequence:
-- 1. Application requests unsubscription from OnSystemCapabilityUpdated notification
--   with VIDEO_STREAMING capability type
-- SDL does:
-- - a. unsubscribe Application from the notification
-- - b. send response to the Application with videoStreamingCapabilities with additionalVideoStreamingCapabilities
--    stored internally
-- 2. HMI sends OnSystemCapabilityUpdated notification with updates of VIDEO_STREAMING capability type for Application
-- SDL does:
-- - a. not resend OnSystemCapabilityUpdated notification with updates of VIDEO_STREAMING capability type
--    to the Application
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/UpdateVideoStreamingCapabilities/common')

--[[ Local Variables ]]
local appSessionId = 1
local notExpected = 0

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Set HMI Capabilities", common.setHMICapabilities)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { common.hmiDefaultCapabilities })
common.Step("RAI", common.registerAppWOPTU)
common.Step("GetSystemCapability with subscribe = true", common.getSystemCapability, { true })

common.Title("Test")
common.Step("GetSystemCapability with subscribe = false", common.getSystemCapability, { false })
common.Step("OnSystemCapabilityUpdated", common.sendOnSystemCapabilityUpdated, { appSessionId, notExpected })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
