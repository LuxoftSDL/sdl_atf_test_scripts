---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3620
---------------------------------------------------------------------------------------------------
-- Description: Check SDL responds with NACK to protected Start Video Service request over 5th SDL protocol
-- if it contains non existed session id
--
-- Steps:
-- 1. Start SDL, HMI, connect mobile device
-- 2. Navigation mobile app is registered via 5th protocol and activated
-- 3. App tries to start protected Video service over 5th SDL protocol with non existed session id
-- SDL does:
--  - send 'OnServiceUpdate' notification to HMI with 'REQUEST_REJECTED'
--  - respond with NACK to start service request
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Defects/7_1/3620/common')

--[[ Local Variables ]]
local isEncrypted = true
local serviceParams = {
  serviceType = common.serviceType.VIDEO,
  serviceName = "VIDEO",
  reqParams = {
    height        = { type = common.bsonType.INT32,  value = 350 },
    width         = { type = common.bsonType.INT32,  value = 800 },
    videoProtocol = { type = common.bsonType.STRING, value = "RAW" },
    videoCodec    = { type = common.bsonType.STRING, value = "H264" }
  }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppUpdatedProtocolVersion)

common.Title("Test")
common.Step("Start protected VIDEO Service, NACK", common.startServiceNACKwithNonExistedSessionId,
  { serviceParams, isEncrypted })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
