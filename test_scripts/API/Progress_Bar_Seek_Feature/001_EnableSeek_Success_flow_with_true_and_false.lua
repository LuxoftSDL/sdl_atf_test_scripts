---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0084-Progress-Bar-Seek-Feature.md
-- Description:
-- In case:
-- 1) Mobile app sends "SetMediaClockTimer" request with valid "enableSeek"(boolean) param to SDL
-- 2) And SDL transfer this request to HMI
-- 3) And HMI responds "SUCCESS"
-- SDL does:
-- 1) Process this response and transfer it to mobile
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Progress_Bar_Seek_Feature/commonProgressBarSeek')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local value = {
  true,
  false
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("App activation", common.activateApp)

runner.Title("Test")
for _, v in pairs(value) do
  runner.Step("App sends SetMediaClockTimer with enableSeek " .. tostring(v), common.SetMediaClockTimer, { v })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)