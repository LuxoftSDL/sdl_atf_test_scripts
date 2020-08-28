---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0190-resumption-data-error-handling.md
--
-- Description:
-- In case:
-- 1. App is in LIMITED HMI level
-- 2. AddCommand, AddSubMenu, CreateInteractionChoiceSet, SetGlobalProperties, SubscribeButton, SubscribeVehicleData,
--  SubscribeWayPoints, CreateWindow (<Rpc_n>) are sent by app
-- 3. Unexpected disconnect and reconnect are performed
-- 4. App re-registers with actual HashId
-- SDL does:
--  - start resumption process
--  - send set of <Rpc_n> requests to HMI
-- 5. HMI responds with <erroneous> resultCode to one request and <successful> for others
-- SDL does:
--  - process responses from HMI
--  - remove already restored data
--  - send set of revert <Rpc_n> requests to HMI (except the one related to <erroneous> response)
--  - respond RegisterAppInterfaceResponse(success=true,result_code=RESUME_FAILED) to mobile application
--  - restore LIMITED HMI level
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Resumption/Handling_errors_from_HMI/commonResumptionErrorHandling')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Common Functions ]]
local function resumptionAppToLimited()
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnResumeAudioSource", {
      appID = common.getHMIAppId() })
  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
    { hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE" })
  :Times(2)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
for k, value in common.pairs(common.rpcs) do
  for _, interface in common.pairs(value) do
    runner.Title("Rpc " .. k .. " error resultCode to interface " .. interface)
    runner.Step("Register app", common.registerAppWOPTU)
    runner.Step("Activate app", common.activateApp)
    runner.Step("DeactivateA app to limited", common.deactivateAppToLimited)
    for rpc in pairs(common.rpcs) do
      runner.Step("Add " .. rpc, common[rpc])
    end
    runner.Step("Add buttonSubscription", common.buttonSubscription)
    runner.Step("Unexpected disconnect", common.unexpectedDisconnect)
    runner.Step("Connect mobile", common.connectMobile)
    runner.Step("Reregister App resumption " .. k, common.reRegisterAppResumeFailed,
      { 1, common.checkResumptionDataWithErrorResponse, resumptionAppToLimited, k, interface})
    runner.Step("Unregister App", common.unregisterAppInterface)
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
