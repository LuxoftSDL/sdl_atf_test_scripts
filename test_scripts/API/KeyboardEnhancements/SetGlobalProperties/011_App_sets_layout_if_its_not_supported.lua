----------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0238-Keyboard-Enhancements.md
----------------------------------------------------------------------------------------------------
-- Description: Check App is unable to set 'keyboardProperties' for unsupported 'keyboardLayout'.
--
-- Steps:
-- 1. App is registered
-- 2. HMI provides 'KeyboardCapabilities' within 'OnSystemCapabilityUpdated' notification
-- with some values in 'supportedKeyboardLayouts'
-- 3. App sends 'SetGlobalProperties' with 'keyboardLayout' in 'KeyboardProperties' which is not
-- in 'supportedKeyboardLayouts' list
-- SDL does:
--  - Transfer request to HMI
-- 4. HMI responds with erroneous 'UNSUPPORTED_RESOURCE' message
-- SDL does:
--  - Respond with 'UNSUPPORTED_RESOURCE', success:false to App with appropriate message in 'info'
----------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/KeyboardEnhancements/common')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local msg = "keyboard layout is not supported"
local dispCaps = common.getDispCaps()
dispCaps.systemCapability.displayCapabilities[1].windowCapabilities[1].keyboardCapabilities = {
  supportedKeyboardLayouts = { "NUMERIC" },
  configurableKeys = { { keyboardLayout = "NUMERIC", numConfigurableKeys = 1 } }
}

--[[ Local Functions ]]
local function sendSetGP()
  local sgpParams = {
    keyboardProperties = {
      keyboardLayout = "QWERTY",
      keypressMode = "SINGLE_KEYPRESS"
    }
  }
  local dataToHMI = common.cloneTable(sgpParams)
  dataToHMI.appID = common.getHMIAppId()
  local cid = common.getMobileSession():SendRPC("SetGlobalProperties", sgpParams)
  common.getHMIConnection():ExpectRequest("UI.SetGlobalProperties", dataToHMI)
  :Do(function(_, data)
      common.getHMIConnection():SendError(data.id, data.method, "UNSUPPORTED_RESOURCE", msg)
    end)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "UNSUPPORTED_RESOURCE", info = msg })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)

runner.Title("Test")
runner.Step("HMI sends OnSCU", common.sendOnSCU, { dispCaps })
runner.Step("App sends SetGP warnings", sendSetGP)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
