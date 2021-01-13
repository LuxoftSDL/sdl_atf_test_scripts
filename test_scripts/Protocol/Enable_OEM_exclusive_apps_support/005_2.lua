---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local vehicleData = {
    ccpu_version = common.vehicleTypeInfoParams.default["ccpu_version"]
  }

--[[ Scenario ]]
common.Title("Test with excluding all not mandatory parameters")
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
local hmiCap = common.setHMIcap(vehicleData)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { hmiCap })

common.Title("Test")
common.Step("Vehicle type data without all not mandatory params in StartServiceAck", common.startRpcService,
  { common.getRpcServiceAckParams(hmiCap) })
common.Step("Vehicle type data without all not mandatory params in RAI response", common.registerAppEx, { vehicleData })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
