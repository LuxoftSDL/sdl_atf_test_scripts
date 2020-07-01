---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0273-webengine-projection-mode.md
--
-- Description:
-- Check that App will be disallowed to register with HMI type WEB_VIEW 
-- when application is disabled in PT
--
-- Precondition:
-- 1. SDL and HMI are started
-- 2. WebEngine device is connected to SDL
-- 3. PT contains record with enabled = false for App1 with all properties for webengine app 
--    and application is enabled by policies.

-- Sequence:
-- 1. Application1 try to register with WEB_VIEW appHMIType
--  a. SDL reject registration of application (resultCode: "DISALLOWED", success: false)
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultMobileAdapterType = "WS"
-- [[ Required Shared Libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ Local Variables ]]
local appSessionId = 1
local appHMIType = { "WEB_VIEW" }
local appProperties = {
  nicknames = { "Test Web Application_1", "Test Web Application_2" },
  policyAppID = "0000001",
  enabled = false,
  authToken = "ABCD12345",
  transportType = "WS",
  hybridAppPreference = "CLOUD",
}
local appsRAIParams = {
  appHMIType = appHMIType,
  syncMsgVersion = {
    majorVersion = 7,
    minorVersion = 0
  }
}

function updatePreloadedPT(pAppId, pAppHMIType)
  local preloadedTable = common.getPreloadedPT()
  local appId = config["application" .. pAppId].registerAppInterfaceParams.fullAppID
  local appPermissions = common.cloneTable(preloadedTable.policy_table.app_policies.default)
  appPermissions.AppHMIType = pAppHMIType
  for key,value in pairs(appProperties) do
    appPermissions[key] = value
  end
  preloadedTable.policy_table.app_policies[appId] = appPermissions
  preloadedTable.policy_table.functional_groupings["DataConsent-2"].rpcs = common.null
  common.setPreloadedPT(preloadedTable)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Setup RegisterAppInterface params", common.setupRAIParams, { appSessionId, appsRAIParams })
common.Step("Add AppHMIType to preloaded policy table", updatePreloadedPT,
  { appSessionId, appHMIType })
common.Step("Start SDL, HMI, connect Mobile", common.start)

common.Title("Test")
common.Step("Register App failed, application is not enabled", common.disallowedRegisterApp, { appSessionId })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)


