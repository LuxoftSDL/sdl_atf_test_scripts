---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0084-Progress-Bar-Seek-Feature.md
-- Description:
-- In case:
-- 1) Mobile app sends "SetMediaClockTimer" request without valid "enableSeek" param to SDL
-- 2) AND received response ( "success": true, "resultCode": "SUCCESS")
-- 3) HMI sends "OnSeekMediaClockTimer" notification to SDL which is valid and allowed by Policies
-- SDL does:
-- 1) Ignore notification
-- 2) Not send OnSeekMediaClockTimer notification to the mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Progress_Bar_Seek_Feature/commonProgressBarSeek')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("App activation", common.activateApp)

runner.Title("Test")
runner.Step("App sends SetMediaClockTimer without enableSeek param", common.SetMediaClockTimer, { nil })
runner.Step("HMI sends OnSetMediaClockTimer notification", common.OnSeekMediaClockTimerUnsuccess, { common.seekTimeParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
