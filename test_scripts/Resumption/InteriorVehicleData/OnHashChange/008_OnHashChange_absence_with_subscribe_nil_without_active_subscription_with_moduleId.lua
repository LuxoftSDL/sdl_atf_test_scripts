---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0188-get-interior-data-resumption.md
--
-- Description: SDL does not send OnHashChange notification to mobile app in case processing of GetInteriorVehicleData
--  without subscribe parameter with custom moduleId
--
-- Precondition:
-- 1. HMI and SDL are started
-- 2. Mobile app with REMOTE_CONTROL hmi type is registered and activated
-- 3. App is not subscribed to modules
--
-- Sequence:
-- 1. GetInteriorVD(module_1, moduleId) is requested
-- SDL does:
-- - a. send GetInteriorVD(module_1, moduleId) request to HMI
-- - b. process successful responses from HMI
-- - c. not send OnHashChange notification to mobile app by receiving GetInteriorVD(module_1, moduleId)
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Resumption/InteriorVehicleData/commonResumptionsInteriorVD')

--[[ Local Variables ]]
local withoutSubscribe = nil
local notExpectNotif = 0
local expectNotif = 1
local isNotCached = false
local isCached = true
local isSubscribed = true

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)

common.Title("Test")
for _, moduleName in pairs(common.modules)do
  local moduleId = common.getModuleId(moduleName, 2)
  common.Step("Absence OnHashChange after GetInteriorVD without subscribe to " .. moduleName, common.GetInteriorVehicleData,
    { moduleName, moduleId, withoutSubscribe, isNotCached, notExpectNotif })
  common.Step("OnHashChange after adding subscription to " .. moduleName, common.GetInteriorVehicleData,
    { moduleName, moduleId, isSubscribed, isNotCached, expectNotif })
  common.Step("Absence OnHashChange after GetInteriorVD without subscribe to " .. moduleName, common.GetInteriorVehicleData,
    { moduleName, moduleId, withoutSubscribe, isCached, notExpectNotif })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
