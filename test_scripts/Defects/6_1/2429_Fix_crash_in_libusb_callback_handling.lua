---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2429
--
-- Description:
-- Successful processing of Heartbeat messages during 5 minutes
--
-- Precondition:
-- 1) "HeartBeat" is switched on
-- 2) SDL and HMI are started.
-- In case:
-- 1) App is registered
-- 2) Wait 5 minutes
-- SDL does:
-- - a) send Heartbeat related messages
-- - b) not close connection by HB timeout reason.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('user_modules/sequences/actions')
local runner = require('user_modules/script_runner')
local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 3
config.heartbeatTimeout = 100

--[[ Local Functions ]]
local function heartBeatOn()
  common.sdl.setSDLIniParameter("HeartBeatTimeout", 100)
end

local function wait5Minutes()
  utils.wait(300000)
  utils.cprint(35, "Waiting 5 minutes ...")
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered",
    { appID = common.getHMIAppId(), unexpectedDisconnect = true })
  :Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("HeartBeat is switched on", heartBeatOn)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)

-- [[ Test ]]
runner.Title("Test")
runner.Step("Wait 5 minutes", wait5Minutes)
runner.Step("Activate App", common.activateApp)

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
