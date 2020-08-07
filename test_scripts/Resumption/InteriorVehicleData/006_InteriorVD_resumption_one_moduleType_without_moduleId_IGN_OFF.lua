---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0188-get-interior-data-resumption.md
--
-- Description: Successful resuming of interior vehicle data after IGN_OFF in case GetInteriorVehicleData was requested
--  with single module and without moduleId
--
-- Precondition:
-- 1. HMI and SDL are started
-- 2. Mobile app with REMOTE_CONTROL hmi type is registered and activated
-- 3. App is subscribed to module_1 via GetInteriorVehicleData(module_1)

-- Sequence:
-- 1. IGN_OFF and IGN_ON are performed
-- 2. App starts registration with actual hashId after SDL restart
-- SDL does:
-- - a. send RC.GetInteriorVD(subscribe=true, module_1, default moduleId) to HMI during resumption data
-- - b. respond RAI(SUCCESS) to mobile app
-- - c. update hashId after successful resumption
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Resumption/InteriorVehicleData/commonResumptionsInteriorVD')

--[[ Local Variables ]]
local isSubscribed = true
local moduleType = common.modules[1]
local withoutModuleId = nil
local appId = 1

--[[ Local Functions ]]
local function checkResumptionData()
  local defaultModuleId = 1
  common.checkModuleResumptionData(moduleType, common.getModuleId(moduleType, defaultModuleId))
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)
common.Step("Add interiorVD subscription", common.GetInteriorVehicleData, { moduleType, withoutModuleId, isSubscribed })

common.Title("Test")
common.Step("Ignition off", common.ignitionOff)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Re-register App resumption data", common.reRegisterApp,
  { appId, checkResumptionData, common.resumptionFullHMILevel })
common.Step("Check subscription with OnInteriorVD", common.onInteriorVD, { moduleType })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
