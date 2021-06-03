---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0084-Progress-Bar-Seek-Feature.md
-- Description:
-- In case:
-- 1) Mobile app sends "SetMediaClockTimer" request with valid "enableSeek"(true) param to SDL
-- 2) AND received response ( "success": false, "resultCode": ERROR)
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

--[[ Local Variables ]]
local requestParams = {
  startTime = {
    hours = 0,
    minutes = 1,
    seconds = 33
  },
  endTime = {
    hours = 0,
    minutes = 59 ,
    seconds = 35
  },
  updateMode = "COUNTUP",
  enableSeek = true
}

local resultCode = {
  "UNSUPPORTED_REQUEST",
  "DISALLOWED",
  "REJECTED",
  "ABORTED",
  "IGNORED",
  "IN_USE",
  "DATA_NOT_AVAILABLE",
  "TIMED_OUT",
  "INVALID_DATA",
  "CHAR_LIMIT_EXCEEDED",
  "INVALID_ID",
  "APPLICATION_NOT_REGISTERED",
  "OUT_OF_MEMORY",
  "TOO_MANY_PENDING_REQUESTS",
  "GENERIC_ERROR",
  "USER_DISALLOWED"
}

--[[ Local Functions ]]
local function SetMediaClockTimer(pResultCode)
  local cid = common.getMobileSession():SendRPC("SetMediaClockTimer", requestParams)

  requestParams.appID = common.getHMIAppId()
  common.getHMIConnection():ExpectRequest("UI.SetMediaClockTimer", requestParams)
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, pResultCode, {})
  end)

  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = pResultCode })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerAppWOPTU)
runner.Step("App activation", common.activateApp)

runner.Title("Test")
for _, v in pairs(resultCode) do
  runner.Step("SetMediaClockTimer with enableSeek= true and received error " .. v .. " from HMI", SetMediaClockTimer, {v})
  runner.Step("HMI sends OnSetMediaClockTimer notification", common.OnSeekMediaClockTimerUnsuccess, { common.seekTimeParams })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
