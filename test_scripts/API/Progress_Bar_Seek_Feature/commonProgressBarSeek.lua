---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")

--[[ Module ]]
local c = actions

--[[ Variables ]]

c.requestParams = {
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
  updateMode = "COUNTUP"
}

c.seekTimeParams = {
  hours = 0,
  minutes = 1,
  seconds = 1
}

--[[ Common Functions ]]

--[[ @SetMediaClockTimer: Successful processing SetMediaClockTimer RPC
--! @parameters:
--! pValue - value for enableSeek parameter
--! @return: none
--]]
function c.SetMediaClockTimer(pValue)
  c.requestParams.enableSeek = pValue
  local cid = c.getMobileSession():SendRPC("SetMediaClockTimer", c.requestParams)

  c.requestParams.appID = c.getHMIAppId()
  c.getHMIConnection():ExpectRequest("UI.SetMediaClockTimer", c.requestParams)
  :Do(function(_, data)
    c.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  c.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ @SetMediaClockTimerUnsuccess: Processing SetMediaClockTimer with ERROR resultCode
--! @parameters:
--! pValue - value for enableSeek parameter
--! pResultCode - result error
--! @return: none
--]]
function c.SetMediaClockTimerUnsuccess(pValue, pResultCode)
  c.requestParams.enableSeek = pValue
  local cid = c.getMobileSession():SendRPC("SetMediaClockTimer", c.requestParams)

  c.getMobileSession():ExpectResponse(cid, { success = false, resultCode = pResultCode })
end

--[[ @OnSeekMediaClockTimer: Successful processing OnSeekMediaClockTimer notification
--! @parameters: none
--! @return: none
--]]
function c.OnSeekMediaClockTimer()
  c.getHMIConnection():SendNotification("UI.OnSeekMediaClockTimer",{
    seekTime = {
      hours = 0,
      minutes = 2,
      seconds = 25
    },
    appID = c.getHMIAppId()
  })

  c.getMobileSession():ExpectNotification("OnSeekMediaClockTimer", {seekTime = {hours = 0, minutes = 2, seconds = 25 }})
  :ValidIf(function()
    if c.requestParams.enableSeek == true then
      return true
    elseif c.requestParams.enableSeek == false or c.requestParams.enableSeek == nil then
      return false, "Mobile app received OnSeekMediaClockTimer notification when enableSeek = false "
    end
  end)
end

--[[ @OnSeekMediaClockTimerUnsuccess: Processing OnSeekMediaClockTimer with invalid parameters
--! @parameters:
--! pParamsFromHMI - parameters for UI.OnSeekMediaClockTimer
--! @return: none
--]]
function c.OnSeekMediaClockTimerUnsuccess(pParamsFromHMI)
  c.getHMIConnection():SendNotification("UI.OnSeekMediaClockTimer",{
    seekTime = { pParamsFromHMI },
    appID = c.getHMIAppId()
  })

  c.getMobileSession():ExpectNotification("OnSeekMediaClockTimer", { seekTime = { pParamsFromHMI } })
  :Times(0)
end

return c
