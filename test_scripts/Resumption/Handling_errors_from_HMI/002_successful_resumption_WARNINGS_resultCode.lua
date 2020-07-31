---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0190-resumption-data-error-handling.md
--
-- Description:
-- In case:
-- 1. Rpc_n for resumptions is added by app
-- 2. Unexpected disconnect and reconnect are performed
-- 3. App reregisters with actual HashId
-- 4. Rpc_n request is sent from SDL to HMI during resumption
-- 5. HMI responds with WARNINGS resultCode to Rpc_n request
-- SDL does:
-- 1. process WARNINGS response from HMI
-- 2. restore persistent data
-- 3. respond RegisterAppInterfaceResponse(success=true,result_code=SUCCESS) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Resumption/Handling_errors_from_HMI/commonResumptionErrorHandling')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local Function ]]
function common.sendResponse(pData)
  common.getHMIConnection():SendResponse(pData.id, pData.method, "WARNINGS", {})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register app", common.registerAppWOPTU)
runner.Step("Activate app", common.activateApp)
runner.Step("Check subscriptions", common.checkSubscriptions, { false })

runner.Title("Test")
for k in pairs(common.rpcs) do
  runner.Step("Add " .. k, common[k])
end
runner.Step("Add buttonSubscription", common.buttonSubscription)
runner.Step("Check subscriptions", common.checkSubscriptions, { true })
runner.Step("Unexpected disconnect", common.unexpectedDisconnect)
runner.Step("Connect mobile", common.connectMobile)
runner.Step("Reregister App resumption data", common.reRegisterAppSuccess,
  { 1, common.checkResumptionDataSuccess, common.resumptionFullHMILevel})
runner.Step("Check subscriptions", common.checkSubscriptions, { true })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
