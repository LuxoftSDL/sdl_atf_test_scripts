---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")
local test = require("user_modules/dummy_connecttest")

--[[ Overridden Functions ]]
local initHMI_onReady_Orig = test.initHMI_onReady
function test:initHMI_onReady(hmi_table)
  return initHMI_onReady_Orig(self, hmi_table, false)
end

--[[ Local Variables ]]
local defaultHmiCap = common.setHMIcap(common.vehicleTypeInfoParams.default)
local customHmiCap = common.setHMIcap(common.vehicleTypeInfoParams.custom)

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.startWithCustomCap, { defaultHmiCap })
common.Step("Ignition off", common.ignitionOff)

common.Title("Test")
common.Step("Start SDL, HMI, connect Mobile, start Session", common.startWithCustomCap, { customHmiCap })
common.Step("Start RPC Service, Vehicle type data in StartServiceAck", common.startRpcService, { common.vehicleTypeInfoParams.default })
common.Step("Vehicle type data in RAI", common.registerAppEx, { common.vehicleTypeInfoParams.default })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)

