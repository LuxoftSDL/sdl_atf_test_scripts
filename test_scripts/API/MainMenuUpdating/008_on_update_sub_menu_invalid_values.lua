---------------------------------------------------------------------------------------------------
-- HMI requests a subemenu is populated

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL

-- Steps:
-- User opens the menu, and the hmi sends UI.OnUpdateSubMenu

-- Expected:
-- Mobile receives notification that the submenu should be updated
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

local defaultOnUpdateSubMenuParam = {
    menuID = 50,
    updateSubCells = true
}

--[[ Local Functions ]]
local function onUpdateSubMenu(pParam, pValue, pTimes)
  local mobileSession = common.getMobileSession()
  local hmi = common.getHMIConnection()
  defaultOnUpdateSubMenuParam.appID = common.getHMIAppId()
  local onSCUP =common.cloneTable(defaultOnUpdateSubMenuParam)
  onSCUP[pParam] = pValue
  hmi:SendNotification("UI.OnUpdateSubMenu", onSCUP)
  onSCUP.appID = nil
  mobileSession:ExpectNotification("OnUpdateSubMenu", onSCUP)
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
runner.Step("onUpdateSubMenu with invalid type menuID parameter", onUpdateSubMenu, { "menuID", "string", 0 })
runner.Step("onUpdateSubMenu with invalid type updateSubCells parameter", onUpdateSubMenu, { "updateSubCells", "string", 0 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
