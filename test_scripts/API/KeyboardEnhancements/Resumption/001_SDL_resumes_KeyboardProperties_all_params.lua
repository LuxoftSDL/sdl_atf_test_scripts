----------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0238-Keyboard-Enhancements.md
----------------------------------------------------------------------------------------------------
-- Description: Check SDL is able to resume previously defined by App 'KeyboardProperties' after
-- unexpected disconnect
--
-- Steps:
-- 1. App is registered
-- 2. HMI provides 'KeyboardCapabilities' within 'OnSystemCapabilityUpdated' notification
-- 3. App sends 'SetGlobalProperties' with some non-default values for 'KeyboardProperties'
-- 4. App unexpectedly disconnects and reconnects
-- SDL does:
--  - Start data resumption process
--  - Send the values defined by App for 'KeyboardProperties' to HMI within 'UI.SetGlobalProperties' request
----------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/KeyboardEnhancements/common')

--[[ Local Variables ]]
local sgpParams = {
  keyboardProperties = {
    language = "EN-US",
    keyboardLayout = "AZERTY",
    keypressMode = "SINGLE_KEYPRESS",
    limitedCharacterList = { "a" },
    autoCompleteList = { "Daemon, Freedom" },
    maskInputCharacters = "DISABLE_INPUT_KEY_MASK",
    customKeys = { "#", "$" }
  }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)

common.Title("Test")
common.Step("HMI sends OnSystemCapabilityUpdated", common.sendOnSystemCapabilityUpdated)
common.Step("App sends SetGlobalProperties", common.sendSetGlobalPropertiesWithHashId,
  { sgpParams, common.result.success })
common.Step("Unexpected disconnect", common.unexpectedDisconnect)
common.Step("Connect mobile", common.connectMobile)
common.Step("Re-register App", common.reRegisterApp, { sgpParams })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
