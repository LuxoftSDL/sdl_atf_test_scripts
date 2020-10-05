---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0308-protocol-nak-reason.md

-- Description: SDL provides reason information in NAck message
-- in case NAck received because PTU is failed during service starting

-- Precondition:
-- 1. SDL and HMI are started
-- 2. Mobile app is registered with 'NAVIGATION' HMI type and with 5 protocol
-- 3. Mobile app is activated
--
-- Steps:
-- 1. Mobile app requests the opening of protected RPC service
-- 2. PTU is triggered to get actual certificated
-- 3. Mobile app provides invalid update in SystemRequest
-- SDL does:
-- - respond with NAck to StartService request because PTU is failed
-- - provide reason information in NAck message
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local rpcServiceParams = {
  reqParams = {
    protocolVersion = { type = common.bsonType.STRING, value = "7.0.0" }
  },
  nackParams = {
    reason = { type = common.bsonType.STRING, value = "Policy Table Update failed" }
  }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Set ForceProtectedService = 0x0A, 0x0B", common.setProtectedServicesInIni)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("PTU", common.policyTableUpdate)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("Start RPC Service, PTU failed, NACK", common.ptuFailedNACK,
  { 1, common.serviceType.RPC, rpcServiceParams.reqParams, rpcServiceParams.nackParams })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
