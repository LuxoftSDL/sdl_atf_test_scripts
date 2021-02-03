---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/SmartDeviceLink/sdl_core/issues/3556
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL sends response to SDL.GetListOfPermission with appId and function group
--  in case the 'default` section contains groups with user_consent_prompt.
--
-- Preconditions:
-- 1. Clean environment
-- 2. Structure groups of section default contain Group "Location_1" with  user_consent_prompt
-- 3. SDL, HMI, Mobile session is started
-- 4. App is registered
-- 5. App is activated
-- Steps:
-- 1. HMI sends GetListOfPermissions requests
-- SDL does:
--  - sends GetListOfPermissions response with allowedFunctions { name = "Location" }
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.restrictions.sdlBuildOptions = {{ extendedPolicy = { "EXTERNAL_PROPRIETARY" }}}
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function updatePreloadedPT()
  local pt = common.sdl.getPreloadedPT()
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = utils.json.null
  pt.policy_table.app_policies.default.groups = { "Base-4", "Location-1" }
  common.sdl.setPreloadedPT(pt)
end

local function getListOfPermissions()
  local rid = common.getHMIConnection():SendRequest("SDL.GetListOfPermissions", { appID = common.getHMIAppId() })
  common.getHMIConnection():ExpectResponse(rid, {
    result = {
      code = 0,
      method = "SDL.GetListOfPermissions",
      allowedFunctions = {{ id = 156072572, name = "Location" }},
      externalConsentStatus = { }
    }
  })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", updatePreloadedPT)
runner.Step("Start SDL, HMI, connect regular mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Send GetListOfPermissions", getListOfPermissions)

runner.Title("Postconditions")
runner.Step("Stop SDL, restore SDL settings and PPT", common.postconditions)
