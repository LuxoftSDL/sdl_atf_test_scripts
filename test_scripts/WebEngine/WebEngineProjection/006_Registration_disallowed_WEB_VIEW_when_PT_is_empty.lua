---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0273-webengine-projection-mode.md
--
-- Description:
-- Check that App will be rejected with HMI type WEB_VIEW 
-- when mobile application has no policy record in local policy table
--
-- Precondition:
-- 1. SDL and HMI are started
-- 2. WebEngine device is connected to SDL

-- Sequence:
-- 1. Application1 try to register with WEB_VIEW appHMIType
--  a. SDL reject registration of application (resultCode: "DISALLOWED", success: false)
-- 2. Application2 register with NAVIGATION appHMIType
--  a. SDL successfully registers application (resultCode: "SUCCESS", success: true)
--  b. SDL creates policy table snapshot and start policy table update
-- 3. Check absence of permissions for rejected application in LPT
--  a. Permission for rejected Application1 is absent in LPT
---------------------------------------------------------------------------------------------------
-- [[ Required Shared Libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ Local Variables ]]
local appSessionId1 = 1
local appSessionId2 = 2
local appHMIType = "WEB_VIEW"

--[[ Local Functions ]]
local function ptUpdate(pTbl)
  pTbl.policy_table.app_policies[common.getConfigAppParams(appSessionId1).fullAppID] = common.getAppDataForPTU(appSessionId1)
end

local function checkAbsenceOfPermissions()
  local ptsTable = common.ptsTable()
  if not ptsTable then
    common.failTestStep("Policy table snapshot was not created")
  elseif ptsTable.policy_table.app_policies["0000001"] ~= nil then
    common.failTestStep("Permission for rejected application is present in LPT")
  end
end

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = { appHMIType }
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 6
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 2
config.application2.registerAppInterfaceParams.syncMsgVersion.majorVersion = 6
config.application2.registerAppInterfaceParams.syncMsgVersion.minorVersion = 2

config.defaultMobileAdapterType = "WS"
common.testSettings.restrictions.sdlBuildOptions = {{ webSocketServerSupport = { "ON" }}}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI", common.start)

common.Title("Test")
common.Step("Register App with WEB_VIEW appHmiType", common.disallowedRegisterApp, { appSessionId1 })
common.Step("Register App with NAVIGATION appHmiType", common.registerApp,{ appSessionId2 })

common.Step("Check absence of permissions for rejected application in LPT", checkAbsenceOfPermissions)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)

