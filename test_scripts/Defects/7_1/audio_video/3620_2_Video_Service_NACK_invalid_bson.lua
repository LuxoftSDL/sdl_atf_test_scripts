---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3620
---------------------------------------------------------------------------------------------------
-- Description: Check SDL responds with NACK to Start Video Service request over 5th SDL protocol
-- if it contains invalid data in bson payload
--
-- Steps:
-- 1. Start SDL, HMI, connect mobile device
-- 2. Navigation mobile app is registered via 5th protocol and activated
-- 3. App tries to start Video service over 5th SDL protocol with invalid data in bson payload
-- SDL does:
--  - send 'OnServiceUpdate' notification to HMI with 'REQUEST_REJECTED'
--  - respond with NACK to start service request
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Defects/7_1/3620/common')

--[[ Local Variables ]]
local appId = 1
local serviceParams = {
  reqParams = {
    height        = { type = common.bsonType.INT32,  value = 350 },
    width         = { type = common.bsonType.INT32,  value = 800 },
    videoProtocol = { type = common.bsonType.STRING, value = "invalid_value" }, -- invalid value
    videoCodec    = { type = common.bsonType.STRING, value = "H264" }
  },
  nackParams = {
    rejectedParams = {
      type = common.bsonType.ARRAY,
      value = {
        [1] = { type = common.bsonType.STRING, value = "videoProtocol" }
      }
    }
  }
}

--[[ Local Functions ]]
local function onServiceUpdateExp()
  common.hmi.getConnection():ExpectNotification("BasicCommunication.OnServiceUpdate",
    { serviceEvent = "REQUEST_RECEIVED", serviceType = "VIDEO" },
    { serviceEvent = "REQUEST_REJECTED", serviceType = "VIDEO" })
  :Times(2)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppUpdatedProtocolVersion)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("Start VIDEO Service, NACK", common.startServiceUnprotectedNACK,
  { appId, common.serviceType.VIDEO, serviceParams.reqParams, serviceParams.nackParams, onServiceUpdateExp })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
