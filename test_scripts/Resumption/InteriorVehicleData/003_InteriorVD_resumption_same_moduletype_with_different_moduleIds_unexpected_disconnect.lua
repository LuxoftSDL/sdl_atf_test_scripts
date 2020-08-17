---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0188-get-interior-data-resumption.md
--
-- Description: Successful resuming of interior vehicle subscription for same moduleType with different moduleIds data
--  after transport disconnect
--
-- Precondition:
-- 1. HMI and SDL are started
-- 2. Mobile app with REMOTE_CONTROL hmi type is registered and activated
-- 3. App is subscribed to module_1 with modueId_1 and module_1 with modueId_2
--
-- Sequence:
-- 1. Transport disconnect and reconnect are performed
-- 2. App starts registration with actual hashId after unexpected disconnect
-- SDL does:
-- - a. send RC.GetInteriorVehicleData(subscribe=true, module_1, moduleId_1) and
--    RC.GetInteriorVehicleData(subscribe=true, module_1, moduleId_2) to HMI during resumption data
-- - b. respond RAI(SUCCESS) to mobile app
-- - c. update hashId after successful resumption
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Resumption/InteriorVehicleData/commonResumptionsInteriorVD')

--[[ Local Variables ]]
local isSubscribed = true
local moduleType = "SEAT"
local moduleId1 = common.getModuleId(moduleType, 1)
local moduleId2 = common.getModuleId(moduleType, 2)
local appSessionId = 1

--[[ Local Functions ]]
local function checkResumptionData()
  local subscriptionsCount  = 2
  local expectedModules = {
    { moduleType = moduleType, moduleId = moduleId1, subscribe = true },
    { moduleType = moduleType, moduleId = moduleId2, subscribe = true }
  }

  common.checkResumptionData(subscriptionsCount, expectedModules)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)
common.Step("Add interiorVD subscription " .. moduleType .. " " .. moduleId1, common.GetInteriorVehicleData,
  { moduleType, moduleId1, isSubscribed })
common.Step("Add interiorVD subscription " .. moduleType .. " " .. moduleId2, common.GetInteriorVehicleData,
  { moduleType, moduleId2, isSubscribed })

common.Title("Test")
common.Step("Unexpected disconnect", common.mobileDisconnect)
common.Step("Connect mobile", common.mobileConnect)
common.Step("Re-register App resumption data", common.reRegisterApp,
  { appSessionId, checkResumptionData, common.resumptionFullHMILevel })
common.Step("Check subscription with OnInteriorVD for " .. moduleType .. " " .. moduleId1, common.onInteriorVD,
  { moduleType, moduleId1 })
common.Step("Check subscription with OnInteriorVD for " .. moduleType .. " " .. moduleId2, common.onInteriorVD,
  { moduleType, moduleId2 })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
