---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0190-resumption-data-error-handling.md
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0188-get-interior-data-resumption.md
--
-- Description:
-- In case:
-- 1. App successfully added SubMenu and is subscribed to Interior Vehicle Data (IVD)
-- 2. Unexpected disconnect and reconnect are performed
-- 3. App re-register with actual HashId
-- 4. SDL starts resumption for App:
--    UI.AddSubMenu, RC.GetInteriorVehicleData requests are sent to HMI
-- 5. HMI responds with error for 'UI.AddSubMenu' request and after with success for 'RC.GetInteriorVehicleData'
-- SDL does:
-- 1. process responses from HMI
-- 2. remove already restored data
-- 3. respond RegisterAppInterfaceResponse(success=true,result_code=RESUME_FAILED) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Resumption/Handling_errors_from_HMI/commonResumptionErrorHandling')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function reRegisterAppsCustom_AnotherRPC()
  local moduleIdValue = common.getModuleControlData(common.defaultModuleType, 1).moduleId

  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered")
  :Do(function(exp, data)
      common.log("BC.OnAppRegistered " .. exp.occurences)
      common.setHMIAppId(data.params.application.appID, exp.occurences)
      common.sendOnSCU(0, exp.occurences)
    end)

  common.getHMIConnection():ExpectRequest("UI.AddSubMenu")
  :Do(function(_, data)
      common.log(data.method)
      common.errorResponse(data, 0)
    end)

  common.getHMIConnection():ExpectRequest("RC.GetInteriorVehicleData",
    { moduleType = common.defaultModuleType, subscribe = true, moduleId = moduleIdValue },
    { moduleType = common.defaultModuleType, subscribe = false, moduleId = moduleIdValue })
  :Do(function(exp, data)
      common.log(data.method)
      local timeToSend = 0
      if exp.occurences == 1 then timeToSend = 1000 end
      common.run.runAfter(function()
        common.log(data.method .. ": SUCCESS")
        local responseHMI = {}
        responseHMI.moduleData = common.getActualModuleIVData(common.defaultModuleType, moduleIdValue)
        responseHMI.isSubscribed = data.params.subscribe
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", responseHMI)
      end, timeToSend)
    end)
  :Times(2)

  common.expOnHMIStatus(1, "FULL")
  common.reRegisterAppCustom(1, "RESUME_FAILED", 0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("Register app1", common.registerAppWOPTU)
runner.Step("Activate app1", common.activateApp)
runner.Step("Add for app1 getInteriorVehicleData", common.getInteriorVehicleData)
runner.Step("Add for app1 addSubMenu", common.addSubMenu)
runner.Step("Check subscriptions for getInteriorVehicleData", common.isSubscribed, { true })
runner.Step("Unexpected disconnect", common.unexpectedDisconnect)
runner.Step("Connect mobile", common.connectMobile)
runner.Step("openRPCserviceForApp1", common.openRPCservice, { 1 })
runner.Step("Reregister Apps resumption", reRegisterAppsCustom_AnotherRPC)
runner.Step("Check subscriptions for getInteriorVehicleData", common.isSubscribed, { false })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
