---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0273-webengine-projection-mode.md
--
-- Description:
-- Check that App will be rejected with HMI type collection {"MEDIA", "WEB_VIEW"}  
-- when application has revoked permissions in policy table
--
-- Precondition:
-- 1. SDL and HMI are started
-- 2. WebEngine device is connected to SDL
-- 3. PT contains record for App1 

-- Sequence:
-- 1. Application1 try to register with WEB_VIEW appHMIType
--  a. SDL reject registration of application (resultCode DISALLOWED, success:"false")
---------------------------------------------------------------------------------------------------
-- [[ Required Shared Libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ Local Variables ]]
local appSessionId = 1
local appHMIType = {"MEDIA", "WEB_VIEW"}

local function updatePreloadedPT(pAppId, pAppHMIType)
  local preloadedTable = common.getPreloadedPT()
  local appId = config["application" .. pAppId].registerAppInterfaceParams.fullAppID
  local appPermissions = common.cloneTable(preloadedTable.policy_table.app_policies.default)
  appPermissions.AppHMIType = pAppHMIType 
  appPermissions.enabled = true
  appPermissions.transportType = "WS"
  appPermissions.hybridAppPreference = "CLOUD"
  preloadedTable.policy_table.app_policies[appId] = common.null
  preloadedTable.policy_table.functional_groupings["DataConsent-2"].rpcs = common.null
  common.setPreloadedPT(preloadedTable)
end

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = appHMIType
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 7
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 0

config.defaultMobileAdapterType = "WS"
common.testSettings.restrictions.sdlBuildOptions = {{ webSocketServerSupport = { "ON" }}}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Add AppHMIType to preloaded policy table", updatePreloadedPT,
  { appSessionId, appHMIType })
common.Step("Start SDL, HMI, connect Mobile", common.start)

common.Title("Test")
common.Step("Register App, PT does not contain WEB_VIEW AppHMIType", common.rejectedRegisterApp, {appSessionId})

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)


