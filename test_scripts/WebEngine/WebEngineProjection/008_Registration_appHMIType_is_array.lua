---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0273-webengine-projection-mode.md
--
-- Description:
-- Check that it is possible to register App with array of HMI types [WEB_VIEW, Media].
--
-- Precondition:
-- 1. SDL and HMI are started
-- 2. WebEngine device is connected to SDL
-- 3. WEB_VIEW and Media appHMITypes are allowed by policy for application (App)

-- Sequence:
-- 1. Application register with WEB_VIEW and MEDIA appHMITypes
--  a. SDL succesfuly registers application (resultCode SUCCESS, success:"true")
---------------------------------------------------------------------------------------------------
-- [[ Required Shared Libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ Local Variables ]]
local appSessionId = 1
local appHMIType = { "WEB_VIEW", "MEDIA" }

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = appHMIType
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 7
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 0

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Add AppHMIType to preloaded policy table", common.updatePreloadedPT,
  { appSessionId, appHMIType })
common.Step("Start SDL, HMI, connect Mobile", common.start)

common.Title("Test")
common.Step("Register App without PTU", common.registerAppWOPTU, { appSessionId })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)

