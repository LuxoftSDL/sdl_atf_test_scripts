---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0084-Progress-Bar-Seek-Feature.md
-- Description:
-- In case:
-- 1) Mobile app sends "SetMediaClockTimer" request with invalid "enableSeek" param to SDL:
--  a) invalid type
--  b) empty value
-- SDL does:
-- 1) Not send request to HMI
-- 2) Respond to App with success:false, "INVALID_DATA"
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Progress_Bar_Seek_Feature/commonProgressBarSeek')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local invalidValue = {
  invalidType = 123,
  emptyValue = ""
}

local errorCode = "INVALID_DATA"

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("App activation", common.activateApp)

runner.Title("Test")
for k, v in pairs(invalidValue) do
  runner.Step("App sends SetMediaClockTimer with incorrect enableSeek " .. tostring(k),
  common.SetMediaClockTimerUnsuccess, { v, errorCode })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
