---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0188-get-interior-data-resumption.md
--
-- Description: SDL does not resume interior vehicle data in 4th ignition cycle
--
-- Precondition:
-- 1. HMI and SDL are started
-- 2. Mobile app with REMOTE_CONTROL hmi type is registered and activated
-- 3. App is subscribed to module_1 via GetInteriorVehicleData(module_1)
--
-- Sequence:
-- 1. IGN_OFF and IGN_ON are performed
-- 2. IGN_OFF and IGN_ON are performed
-- 3. IGN_OFF and IGN_ON are performed
-- 4. App starts registration with actual hashId after IGN_ON in 4th ignition cycle
-- SDL does:
-- - a. not resume persistent data - not send RC.GetInteriorVD(subscribe=true, module_1)
-- - b. respond RAI(RESUME_FAILED) to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Resumption/InteriorVehicleData/commonResumptionsInteriorVD')

--[[ Local Variables ]]
local isSubscribed = true
local isUnsubscribed = false
local moduleType = common.modules[1]
local default = nil
local appSessionId = 1

--[[ Local Functions ]]
local function checkResumptionData()
  common.getHMIConnection():ExpectRequest("RC.GetInteriorVehicleData")
  :Times(0)
end

local function absenceHMIlevelResumption()
  common.getMobileSession(appSessionId):ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)
common.Step("Add interiorVD subscription", common.GetInteriorVehicleData, { moduleType, default, isSubscribed })

common.Title("Test")
common.Step("Ignition off", common.ignitionOff)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Ignition off", common.ignitionOff)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Ignition off", common.ignitionOff)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Re-register App resumption data", common.reRegisterApp,
  { appSessionId, checkResumptionData, absenceHMIlevelResumption, "RESUME_FAILED" })
common.Step("Check subscription with OnInteriorVD", common.onInteriorVD, { moduleType, default, isUnsubscribed})

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
