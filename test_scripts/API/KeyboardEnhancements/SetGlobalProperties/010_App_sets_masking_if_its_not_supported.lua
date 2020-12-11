----------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0238-Keyboard-Enhancements.md
----------------------------------------------------------------------------------------------------
-- Description: Check App is unable to mask input characters via 'maskInputCharacters' parameter
-- within 'SetGlobalProperties' request if masking is not supported by HMI
--
-- Steps:
-- 1. App is registered
-- 2. HMI provides 'KeyboardCapabilities' within 'OnSystemCapabilityUpdated' notification
-- where 'maskInputCharactersSupported' = false
-- 3. App sends 'SetGlobalProperties' with 'maskInputCharacters' in 'KeyboardProperties'
-- SDL does:
--  - Transfer request to HMI
-- 4. HMI responds with erroneous 'WARNINGS' message
-- SDL does:
--  - Respond with 'WARNINGS', success:true to App with appropriate message in 'info'
----------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/KeyboardEnhancements/common')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local msg = "keyboard masking is not supported"

--[[ Local Functions ]]
local function sendSetGP()
  local sgpParams = {
    keyboardProperties = {
      keyboardLayout = "NUMERIC",
      maskInputCharacters = "ENABLE_INPUT_KEY_MASK"
    }
  }
  local dataToHMI = common.cloneTable(sgpParams)
  dataToHMI.appID = common.getHMIAppId()
  local cid = common.getMobileSession():SendRPC("SetGlobalProperties", sgpParams)
  common.getHMIConnection():ExpectRequest("UI.SetGlobalProperties", dataToHMI)
  :Do(function(_, data)
      common.getHMIConnection():SendError(data.id, data.method, "WARNINGS", msg)
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "WARNINGS", info = msg })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)

runner.Title("Test")
runner.Step("HMI sends OnSCU", common.sendOnSCU)
runner.Step("App sends SetGP warnings", sendSetGP)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
