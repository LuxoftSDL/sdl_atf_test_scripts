---------------------------------------------------------------------------------------------------
-- HMI requests a missing cmdIcon be updated from mobile

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL

-- Steps:
-- User opens the menu, and the hmi sends UI.OnUpdateFile

-- Expected:
-- Mobile receives notification that the file should be updated
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

local fileNameMin = string.rep("a", 1)
local fileNameMax = string.rep("a", 255)
local fileNameOutOfRange = string.rep("a", 256)

--[[ Local Functions ]]
local function ShowMenuRequestFile(pFileName, pTimes)
  local onUpdateFileParams = {
    fileName = pFileName
}
  local mobileSession = common.getMobileSession()
  local hmi = common.getHMIConnection()
  onUpdateFileParams.appID = common.getHMIAppId()
  hmi:SendNotification("UI.OnUpdateFile", onUpdateFileParams)
  onUpdateFileParams.appID = nil
  mobileSession:ExpectNotification("OnUpdateFile", onUpdateFileParams)
  :Times(pTimes)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("OnUpdateFile with fileName min value", ShowMenuRequestFile, { fileNameMin, 1 })
runner.Step("OnUpdateFile with fileName max value", ShowMenuRequestFile, { fileNameMax, 1 })
runner.Step("OnUpdateFile with fileName out of range", ShowMenuRequestFile, { fileNameOutOfRange, 0 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
