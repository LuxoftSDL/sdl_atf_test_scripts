---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0188-get-interior-data-resumption.md
--
-- Description: Successful resuming of interior vehicle data for two apps after IGN_OFF in case apps are subscribed to
--  the same moduleTypes with different moduleIds
--
-- Precondition:
-- 1. HMI and SDL are started
-- 2. Mobile app1 and app2 with REMOTE_CONTROL hmi type are registered and activated
-- 3. App1 is subscribed to module_1 with moduleId_1
-- 4. App2 is subscribed to module_1 with moduleId_2
--
-- Sequence:
-- 1. IGN_OFF and IGN_ON are performed
-- 2. Apps start registration with actual hashIds after SDL restart
-- SDL does:
-- - a. send RC.GetInteriorVD(module_1, moduleId_1) and RC.GetInteriorVD(module_1, moduleId_2)
--   to HMI during resumption data
-- - b. respond RAI(SUCCESS) to both mobile apps
-- - c. update hashId after successful resumption
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Resumption/InteriorVehicleData/commonResumptionsInteriorVD')

--[[ Local Variables ]]
local moduleType = "SEAT"
local moduleId1 = common.getModuleId(moduleType, 1)
local moduleId2 = common.getModuleId(moduleType, 2)
local isSubscribe = true
local default = nil
local appSessionId1 = 1
local appSessionId2 = 2
local expected = 1
local notExpected = 0

--[[ Local Functions ]]
local function checkResumptionData()
  common.getHMIConnection():ExpectRequest("RC.GetInteriorVehicleData",
    {
      moduleType = moduleType,
      subscribe = true,
      moduleId = moduleId1
    },
    {
      moduleType = moduleType,
      subscribe = true,
      moduleId = moduleId2
    })
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {
        moduleData = common.getActualModuleIVData(data.params.moduleType, data.params.moduleId), isSubscribed = true })
    end)
  :Times(2)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App1 registration", common.registerAppWOPTU, { appSessionId1 })
common.Step("App2 registration", common.registerAppWOPTU, { appSessionId2 })
common.Step("App1 activation", common.activateApp, { appSessionId1 })
common.Step("App2 activation", common.activateApp, { appSessionId2 })
common.Step("App1 interiorVD subscription for " .. moduleType .. " " .. moduleId1,
  common.GetInteriorVehicleData, { moduleType, moduleId1, isSubscribe, default, default, appSessionId1 })
common.Step("App2 interiorVD subscription for " .. moduleType .. " " .. moduleId2,
  common.GetInteriorVehicleData, { moduleType, moduleId2, isSubscribe, default, default, appSessionId2  })

common.Title("Test")
common.Step("Ignition off", common.ignitionOff)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Open service for app1", common.sessionCreationOpenRPCservice, { appSessionId1 })
common.Step("Open service for app2", common.sessionCreationOpenRPCservice, { appSessionId2 })
common.Step("Reregister Apps resumption data", common.reRegisterApps,
  { checkResumptionData })
common.Step("Check subscription with OnInteriorVD " .. moduleType .. " " .. moduleId1, common.onInteriorVD2Apps,
  { moduleType, expected, notExpected, moduleId1 })
common.Step("Check subscription with OnInteriorVD " .. moduleType .. " " .. moduleId2, common.onInteriorVD2Apps,
  { moduleType, notExpected, expected, moduleId2 })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
