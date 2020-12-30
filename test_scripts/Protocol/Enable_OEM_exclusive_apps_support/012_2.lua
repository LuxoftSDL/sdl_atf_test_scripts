---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Overridden Functions ]]
local initHMI_onReady_Orig = common.initHMI_onReady
function common:initHMI_onReady(hmi_table)
  return initHMI_onReady_Orig(self, hmi_table, false)
end

--[[ Local Variables ]]
local removeCreatedSession = true
local tcs = {
  [01] = string.rep("a", 501), -- out of upper bound value
  [02] = "", -- out of lower bound value
  [03] = 1 -- invalid type
}
local defaultHmiCap = common.setHMIcap(common.vehicleTypeInfoParams.default)
local rpcServiceAckParams = common.getRpcServiceAckParams(defaultHmiCap)

--[[ Local Functions ]]
local function setHmiCap(pTC, pVehicleTypeInfo)
  local hmiCap = common.setHMIcap(pVehicleTypeInfo)
  local systemInfoParams = hmiCap.BasicCommunication.GetSystemInfo.params
  systemInfoParams.systemHardwareVersion = pTC
  return hmiCap
end

--[[ Scenario ]]
for tc, data in common.spairs(tcs) do
  common.Title("TC[" .. string.format("%03d", tc) .. "]")
  common.Title("Preconditions")
  common.Step("Clean environment", common.preconditions)
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.startWithCustomCap, { defaultHmiCap })
  common.Step("Ignition off", common.ignitionOff)
  local customHmiCap = setHmiCap(data, common.vehicleTypeInfoParams.custom)

  common.Title("Test")
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.startWithCustomCap, { customHmiCap })
  common.Step("Start RPC Service, Vehicle type data in StartServiceAck", common.startRpcService,
    { rpcServiceAckParams })

  common.Title("Postconditions")
  common.Step("Stop SDL", common.postconditions, { removeCreatedSession })
end
