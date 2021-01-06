---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local appSessionId1 = 1
local appSessionId2 = 2
local hmiCap = common.setHMIcap(common.vehicleTypeInfoParams.default)
local rpcServiceAckParams = common.getRpcServiceAckParams(hmiCap)

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.startWithCustomCap, { hmiCap })

common.Title("Test")
common.Step("Start RPC Service, Vehicle type data in StartServiceAck for App1", common.startRpcService,
  { rpcServiceAckParams, appSessionId1 })
common.Step("Vehicle type data in RAI App1", common.registerAppEx,
  { common.vehicleTypeInfoParams.default, appSessionId1 })
common.Step("Start RPC Service, Vehicle type data in StartServiceAck for App2", common.startRpcService,
  { rpcServiceAckParams, appSessionId2 })
common.Step("Vehicle type data in RAI App2", common.registerAppEx,
  { common.vehicleTypeInfoParams.default, appSessionId2 })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
