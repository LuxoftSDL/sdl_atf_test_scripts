----------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0238-Keyboard-Enhancements.md
----------------------------------------------------------------------------------------------------
-- Description: Check SDL is able to resume cached language, keyboardLayout from KeyboardProperties
-- after unexpected disconnect
--
-- Steps:
-- 1. App is registered
-- 2. HMI provides 'KeyboardCapabilities' within 'OnSystemCapabilityUpdated' notification
-- 3. App sends 'SetGlobalProperties' with some non-default values for 'KeyboardProperties'
-- 4. App sends 'SetGlobalProperties' with empty array in autoCompleteList in 'KeyboardProperties'
-- SDL does:
--  - Keep values for language, keyboardLayout
--  - Reset all other parameter values to the default values
-- 5. App unexpectedly disconnects and reconnects
-- SDL does:
--  - Start data resumption process
--  - Send language, keyboardLayout defined by App in 'KeyboardProperties' to HMI
--   within 'UI.SetGlobalProperties' request
----------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/KeyboardEnhancements/common')

--[[ Local Variables ]]
local hashId
local sgpParams_1 = {
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

local sgpParams_2 = {
  vrHelpTitle = "title",
  vrHelp = { { text = "text1", position = 1 } },
  keyboardProperties = {
    autoCompleteList = common.json.EMPTY_ARRAY
  }
}

local sgpParams_resumption = {
  vrHelpTitle = "title",
  vrHelp = { { text = "text1", position = 1 } },
  keyboardProperties = {
    language = "EN-US",
    keyboardLayout = "AZERTY"
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
        local dataToHMI = common.cloneTable(sgpParams_resumption)
        common.getHMIConnection():ExpectRequest("UI.SetGlobalProperties", dataToHMI)
        :Do(function(_, data)
            common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
          end)
        :ValidIf(function(_, data)
            if not common.isTableEqual(data.params.keyboardProperties, dataToHMI.keyboardProperties) then
              return false, "Unexpected number of parameters or parameter values are received"
               .. " in UI.SetGlobalProperties request"
               .. "\n Expected data: " .. common.tableToString(dataToHMI.keyboardProperties)
               .. "\n Actual data: " .. common.tableToString(data.params.keyboardProperties)
            end
            return true
          end)
      end)
    common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  end)
end

local function sendSetGlobalProperties(...)
  common.getMobileSession():ExpectNotification("OnHashChange")
  :Do(function(_, data)
      hashId = data.payload.hashID
    end)
  common.sendSetGlobalProperties(...)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)

common.Title("Test")
common.Step("HMI sends OnSystemCapabilityUpdated", common.sendOnSystemCapabilityUpdated)
common.Step("App sends SetGlobalProperties first request", sendSetGlobalProperties,
  { sgpParams_1, common.result.success })
common.Step("App sends SetGlobalProperties second request", sendSetGlobalProperties,
  { sgpParams_2, common.result.success })
common.Step("Unexpected disconnect", common.unexpectedDisconnect)
common.Step("Connect mobile", common.connectMobile)
common.Step("Re-register App", reRegisterApp)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
