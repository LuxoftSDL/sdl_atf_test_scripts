---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local defaultHmiCap = common.setHMIcap(common.vehicleTypeInfoParams.default)
local customHmiCap = common.setHMIcap(common.vehicleTypeInfoParams.custom)
local rpcServiceAckParams = common.getRpcServiceAckParams(customHmiCap)

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { defaultHmiCap, common.isCacheUsed })
common.Step("Ignition off", common.ignitionOff)

common.Title("Test")
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { customHmiCap, common.isCacheUsed })
common.Step("Start RPC Service, Vehicle type data in StartServiceAck",
  common.startRpcService, { rpcServiceAckParams })
common.Step("Vehicle type data in RAI", common.registerAppEx, { common.vehicleTypeInfoParams.custom })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
