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
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/KeyboardEnhancements/common')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local hashId
local sgpParams = {
  vrHelpTitle = "title",
  vrHelp = { { text = "text1", position = 1 } },
  keyboardProperties = {
    language = "EN-US",
    keyboardLayout = "AZERTY",
    keypressMode = "SINGLE_KEYPRESS",
    limitedCharacterList = { "a" },
    autoCompleteList = { "Daemon, Freedom" },
    maskInputCharacters = "DISABLE_INPUT_KEY_MASK",
    customizeKeys = { "#", "$" }
  }
}

--[[ Local Functions ]]
local function reRegisterApp()
  common.getMobileSession():StartService(7)
  :Do(function()
    local appParams = common.cloneTable(common.getParams())
    appParams.hashID = hashId
    local cid = common.getMobileSession():SendRPC("RegisterAppInterface", appParams)
    common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered")
    :Do(function()
        local dataToHMI = common.cloneTable(sgpParams)
        common.getHMIConnection():ExpectRequest("UI.SetGlobalProperties", dataToHMI)
        :Do(function(_, data)
            common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
          end)
      end)
    common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  end)
end

local function sendSetGP(...)
  common.getMobileSession():ExpectNotification("OnHashChange")
  :Do(function(_, data)
      hashId = data.payload.hashID
    end)
  common.sendSetGP(...)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)

runner.Title("Test")
runner.Step("HMI sends OnSCU", common.sendOnSCU)
runner.Step("App sends SetGP", sendSetGP, { sgpParams, common.result.success })
common.Step("Unexpected disconnect", common.unexpectedDisconnect)
common.Step("Connect mobile", common.connectMobile)
common.Step("Re-register App", reRegisterApp)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
