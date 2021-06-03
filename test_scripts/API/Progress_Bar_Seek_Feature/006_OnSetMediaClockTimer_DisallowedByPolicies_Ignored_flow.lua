---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0084-Progress-Bar-Seek-Feature.md
-- Description:
-- In case:
-- 1) Mobile app sends "SetMediaClockTimer" request with valid "enableSeek"(true) param to SDL
-- 2) AND received response ( "success": true, "resultCode": "SUCCESS")
-- 3) HMI sends "OnSeekMediaClockTimer" notification to SDL which is valid but not allowed by Policies
-- SDL does:
-- 1) Ignore notification
-- 2) Not re-send OnSeekMediaClockTimer notification to the mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Progress_Bar_Seek_Feature/commonProgressBarSeek')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function pTUpdateFunc(pTbl)
  pTbl.policy_table.functional_groupings["Base-4"].rpcs.OnSetMediaClockTimer = nil
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { pTUpdateFunc })
runner.Step("App activation", common.activateApp)
runner.Step("App sends SetMediaClockTimer with enableSeek = true", common.SetMediaClockTimer, { true })

runner.Title("Test")
runner.Step("HMI sends OnSetMediaClockTimer notification", common.OnSeekMediaClockTimerUnsuccess, { common.seekTimeParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
