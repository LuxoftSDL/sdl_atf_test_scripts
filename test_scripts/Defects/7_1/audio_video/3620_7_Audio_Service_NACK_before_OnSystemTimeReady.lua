---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3620
---------------------------------------------------------------------------------------------------
-- Description: Check SDL responds with NACK to protected Start Audio Service request over 5th SDL protocol
-- if BC.OnSystemTimeReady notification has not been received by SDL
--
-- Steps:
-- 1. Start SDL, HMI, connect mobile device
-- 2. Navigation mobile app is registered via 5th protocol and activated
-- 3  HMI has not sent BC.OnSystemTimeReady notification
-- 4. App tries to start protected Audio service over 5th SDL protocol with valid data
-- SDL does:
--  - send 'OnServiceUpdate' notification to HMI with 'REQUEST_REJECTED'
--  - respond with NACK to start service request
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Defects/7_1/3620/common')

--[[ Local Variables ]]
local serviceParams = {
  serviceType = common.serviceType.PCM,
  serviceName = "AUDIO",
  reqParams = {
    mtu = { type = common.bsonType.INT64, value = 131072 }
  },
  nackParams = {
    reason = {
      type = common.bsonType.STRING ,
      value = "System time provider is not ready"
    }
  }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.startWithoutOnSystemTimeReady)
common.Step("App registration", common.registerAppUpdatedProtocolVersion)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("Start protected AUDIO Service, NACK", common.startProtectedServiceWithOnServiceUpdate, { serviceParams })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
