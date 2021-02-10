---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3620
---------------------------------------------------------------------------------------------------
-- Description: Check SDL responds with NACK to Start RPC Service request over 5th SDL protocol
-- if it contains invalid data in bson payload
--
-- Steps:
-- 1. Start SDL, HMI, connect mobile device
-- 2. App tries to start RPC service over 5th SDL protocol with invalid data in bson payload
-- SDL does:
--  - send 'OnServiceUpdate' notification to HMI with 'REQUEST_REJECTED'
--  - respond with NACK to start service request
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local ssl = require("test_scripts/Security/SSLHandshakeFlow/common")
local bson = require('bson4lua')
local constants = require("protocol_handler/ford_protocol_constants")
local utils = require('user_modules/utils')

--[[ General configuration parameters ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 5

--[[ Local Variables ]]
local bsonType = {
  STRING = 0x02,
  ARRAY = 0x04
}

--[[ Local Functions ]]
local function startRpcServiceNACK()
  local payload = {
    protocolVersion = {
      type = bsonType.STRING,
      value = "invalid_value"
    }
  }
  local mobSession = common.getMobileSession()
  local msg = {
    serviceType = constants.SERVICE_TYPE.RPC,
    frameType = constants.FRAME_TYPE.CONTROL_FRAME,
    frameInfo = constants.FRAME_INFO.START_SERVICE,
    sessionId = 0,
    encryption = false,
    binaryData = bson.to_bytes(payload)
  }
  mobSession:Send(msg)
  mobSession:ExpectControlMessage(constants.SERVICE_TYPE.RPC, {
    frameInfo = constants.FRAME_INFO.START_SERVICE_NACK,
    encryption = false
  })
  :ValidIf(function(_, data)
      local exp = {
        rejectedParams = {
          type = bsonType.ARRAY,
          value = {
            [1] = { type = bsonType.STRING, value = "protocolVersion" }
          }
        }
      }
      local act = bson.to_table(data.binaryData)
      return compareValues(exp, act, "binaryData")
    end)
  :Timeout(1000)
  common.hmi.getConnection():ExpectNotification("BasicCommunication.OnServiceUpdate",
    { serviceEvent = "REQUEST_RECEIVED", serviceType = "RPC" },
    { serviceEvent = "REQUEST_REJECTED", serviceType = "RPC" })
  :Times(2)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("Start RPC Service, NACK", startRpcServiceNACK)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
