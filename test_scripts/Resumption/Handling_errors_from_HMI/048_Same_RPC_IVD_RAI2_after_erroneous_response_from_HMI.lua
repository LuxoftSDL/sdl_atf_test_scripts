---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0190-resumption-data-error-handling.md
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0188-get-interior-data-resumption.md
--
-- Description:
-- In case:
-- 1. App1 and App2 subscribed to <RPC>
-- 2. Unexpected disconnect and reconnect are performed
-- 3. App1 re-registers with actual HashId
-- 4. Resumption for App1 is started:
--    <RPC> related to App1 is sent from SDL to HMI
-- 5. HMI responds with error resultCode to <RPC> related to App1
-- 6. App2 re-registers with actual HashId
-- 7. SDL doesn't send revert <RPC> request to HMI
-- 8. SDL doesn't restore subscription to <RPC> and responds RAI_Response(success=true,resultCode=RESUME_FAILED) to App1
-- 9. SDL continue resumption for App2:
--    <RPC> related to App2 is sent from SDL to HMI
-- 10. HMI responds with success to <RPC> related to App2
-- 11. SDL restores subscription for App2 and responds RAI_Response(success=true,resultCode=SUCCESS) to App2
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Resumption/Handling_errors_from_HMI/commonResumptionErrorHandling')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("Register app1", common.registerAppWOPTU)
runner.Step("Register app2", common.registerAppWOPTU, { 2 })
runner.Step("Activate app1", common.activateApp)
runner.Step("Activate app2", common.activateApp, { 2 })
runner.Step("Add for app1 getInteriorVehicleData subscription", common.getInteriorVehicleData, { 1, false })
runner.Step("Add for app2 getInteriorVehicleData subscription", common.getInteriorVehicleData, { 2, true })
runner.Step("Unexpected disconnect", common.unexpectedDisconnect)
runner.Step("Connect mobile", common.connectMobile)
runner.Step("openRPCserviceForApp1", common.openRPCservice, { 1 })
runner.Step("openRPCserviceForApp2", common.openRPCservice, { 2 })
runner.Step("Reregister Apps resumption", common.reRegisterAppsCustom_SameRPC,
  { common.timeToRegApp2.AFTER_ERRONEOUS_RESPONSE, "getInteriorVehicleData" })
runner.Step("Check subscriptions for getInteriorVehicleData", common.isSubscribed, { false, true })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
