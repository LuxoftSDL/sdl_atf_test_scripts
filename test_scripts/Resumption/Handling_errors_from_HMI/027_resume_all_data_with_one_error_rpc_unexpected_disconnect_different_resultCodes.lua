---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0190-resumption-data-error-handling.md
--
-- Description:
-- Check data resumption is failed in case if HMI responds with any <erroneous> result code to request from SDL
--
-- In case:
-- 1. AddSubMenu for resumption is sent by app
-- 2. Unexpected disconnect and reconnect are performed
-- 3. App re-registers with actual HashId
-- SDL does:
--  - start resumption process
--  - send UI.AddSubMenu request to HMI
-- 4. HMI responds with <erroneous> resultCode to UI.AddSubMenu request
-- SDL does:
--  - process response from HMI
--  - respond RegisterAppInterfaceResponse(success=true,result_code=RESUME_FAILED) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Resumption/Handling_errors_from_HMI/commonResumptionErrorHandling')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local resultCodes = {
  "UNSUPPORTED_REQUEST",
  "DISALLOWED",
  "REJECTED",
  "ABORTED",
  "IGNORED",
  "IN_USE",
  "DATA_NOT_AVAILABLE",
  "TIMED_OUT",
  "INVALID_DATA",
  "CHAR_LIMIT_EXCEEDED",
  "INVALID_ID",
  "DUPLICATE_NAME",
  "APPLICATION_NOT_REGISTERED",
  "OUT_OF_MEMORY",
  "TOO_MANY_PENDING_REQUESTS",
  "NO_APPS_REGISTERED",
  "NO_DEVICES_CONNECTED",
  "USER_DISALLOWED",
  "READ_ONLY"
}

--[[ Local Functions ]]
local function reRegisterApp(pAppId, pErrorCode)
  local mobSession = common.getMobileSession(pAppId)
  mobSession:StartService(7)
  :Do(function()
      local params = common.cloneTable(common.getConfigAppParams(pAppId))
      params.hashID = common.hashId[pAppId]
      local corId = mobSession:SendRPC("RegisterAppInterface", params)
      common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered", {
          application = { appName = common.getConfigAppParams(pAppId).appName }
        })
      mobSession:ExpectResponse(corId, { success = true, resultCode = "RESUME_FAILED" })
      :Do(function()
          mobSession:ExpectNotification("OnPermissionsChange")
        end)
    end)
  common.getHMIConnection():ExpectRequest("UI.AddSubMenu",common.resumptionData[pAppId].addSubMenu.UI)
  :Do(function(_, data)
      common.getHMIConnection():SendError(data.id, data.method, pErrorCode)
    end)

  common.resumptionFullHMILevel(pAppId)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
for _, code in common.pairs(resultCodes) do
  runner.Step("Register app", common.registerAppWOPTU)
  runner.Step("Activate app", common.activateApp)
  runner.Step("Add addSubMenu", common.addSubMenu)
  runner.Step("Unexpected disconnect", common.unexpectedDisconnect)
  runner.Step("Connect mobile", common.connectMobile)
  runner.Step("Reregister App resumption with error code " .. code, reRegisterApp, { 1, code })
  runner.Step("Unregister App", common.unregisterAppInterface)
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
