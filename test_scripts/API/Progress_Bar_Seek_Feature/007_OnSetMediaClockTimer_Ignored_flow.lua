---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0084-Progress-Bar-Seek-Feature.md
-- Description:
-- In case:
-- 1) Mobile app sends "SetMediaClockTimer" request with valid "enableSeek"(true) param to SDL
-- 2) AND received response ( "success": true, "resultCode": "SUCCESS")
-- 3) HMI sends invalid "OnSeekMediaClockTimer" notification to SDL:
--  a) invalid data type
--  b) invalid structure
--  c) value out of bound
--  d) missing mandatory
-- SDL does:
-- 1) Ignore notification
-- 2) Not send OnSeekMediaClockTimer notification to the mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Progress_Bar_Seek_Feature/commonProgressBarSeek')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local invalidValue = {
  invalidDataType = { hours = "Invalid data type", minutes = 2, seconds = 30 },
  invalidStructure = { hours = { 12 }, minutes = 2, seconds = 30 },
  missingMandatory = { minutes = 2, seconds = 30 },
  valueOutOfBound = { hours = 61 , minutes = 2, seconds = 30 }
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("App activation", common.activateApp)
runner.Step("App sends SetMediaClockTimer with enableSeek = true", common.SetMediaClockTimer, { true })

runner.Title("Test")
for k, v in pairs(invalidValue) do
  runner.Step("HMI sends OnSetMediaClockTimer notification with " .. tostring(k),
  common.OnSeekMediaClockTimerUnsuccess, { v })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
