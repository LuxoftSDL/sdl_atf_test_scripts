---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0190-resumption-data-error-handling.md
--
-- Description:
-- TBA
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Resumption/Handling_errors_from_HMI/commonResumptionErrorHandling')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.checkAllValidations = true

-- [[ Local Variables ]]
local isRAIResponseSent = {
  [1] = false,
  [2] = false
}

-- [[ Local Functions ]]
local function sendResponse(pData, pDelay)
  local function response()
    common.log(pData.method .. ": GENERIC_ERROR")
    common.getHMIConnection():SendError(pData.id, pData.method, "GENERIC_ERROR", "info message")
  end
  common.run.runAfter(response, pDelay)
end

local function checkResumptionData()

  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered")
  :Do(function(exp, data)
      common.log("BC.OnAppRegistered " .. exp.occurences)
      common.setHMIAppId(data.params.application.appID, exp.occurences)
      common.sendOnSCU(0, exp.occurences)
    end)
  :Times(2)

  common.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData",
    { gps = true })
  :Do(function(exp, data)
      common.log(data.method)
      if exp.occurences == 1 then
        sendResponse(data, 300)
      end
    end)
  :ValidIf(function()
      if isRAIResponseSent[1] then
        return false, "Response for RAI1 is sent earlier than SubscribeVehicleData request to HMI"
      end
      return true
    end)
  :ValidIf(function()
      if isRAIResponseSent[2] then
        return false, "Response for RAI2 is sent earlier than SubscribeVehicleData request to HMI"
      end
      return true
    end)
  :Times(1)

  common.getHMIConnection():ExpectRequest("VehicleInfo.UnsubscribeVehicleData")
  :Do(function(_, data) common.log(data.method) end)
  :Times(0)

  common.expOnHMIStatus(1, "LIMITED")
  common.expOnHMIStatus(2, "FULL")

  common.registerAppCustom(1, "RESUME_FAILED", 0)
  :Do(function() isRAIResponseSent[1] = true end)
  common.registerAppCustom(2, "RESUME_FAILED", 0)
  :Do(function() isRAIResponseSent[2] = true end)

end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("Register app1", common.registerAppWOPTU)
runner.Step("Register app2", common.registerAppWOPTU, { 2 })
runner.Step("Activate app1", common.activateApp)
runner.Step("Activate app2", common.activateApp, { 2 })
runner.Step("Add for app1 subscribeVehicleData gps", common.subscribeVehicleData)
runner.Step("Add for app2 subscribeVehicleData gps", common.subscribeVehicleData, { 2, nil, 0 })
runner.Step("Unexpected disconnect", common.unexpectedDisconnect)
runner.Step("Connect mobile", common.connectMobile)
runner.Step("openRPCserviceForApp1", common.openRPCservice, { 1 })
runner.Step("openRPCserviceForApp2", common.openRPCservice, { 2 })
runner.Step("Reregister Apps resumption", checkResumptionData)
runner.Step("Check subscriptions for gps", common.sendOnVehicleData, { "gps", false, true })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
