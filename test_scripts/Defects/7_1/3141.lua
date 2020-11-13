---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/2935, 3141
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
-- local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]

--[[ Local Functions ]]
local function ptUpdate(pt)
  pt.policy_table.functional_groupings["Base-4"].rpcs["DialNumber"] = {
    hmi_levels = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
  }
end

local function unexpectedDisconnect()
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = true })
  common.mobile.disconnect()
end

local function dialNumber(pDelay)
  local requestParams = {
    number = "#3804567654*"
  }
  local cid = common.getMobileSession():SendRPC("DialNumber", requestParams)
  common.getHMIConnection():ExpectRequest("BasicCommunication.DialNumber")
  :Do(function(_, data)
      unexpectedDisconnect()
      local function hmiResponse()
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
      end
      common.run.runAfter(hmiResponse, pDelay)
      common.run.wait(100)
    end)
  -- common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

local function reRegisterApp()
  common.mobile.connect()
  :Do(function()
      common.registerAppWOPTU()
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { ptUpdate })

runner.Step("Close session", unexpectedDisconnect)

runner.Title("Test")
for i = 1, 10 do
  runner.Title("Iteration " .. i)
  for delay = 15, 25 do
    runner.Step("Register App", reRegisterApp)
    runner.Step("Send request from App and disconnect, delay " .. delay, dialNumber, { delay })
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
