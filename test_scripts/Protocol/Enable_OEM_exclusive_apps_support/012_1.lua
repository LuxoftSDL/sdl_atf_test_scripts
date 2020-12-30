---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local removeCreatedSession = true
local tcs = {
  [01] = string.rep("a", 501), -- out of upper bound value
  [02] = "", -- out of lower bound value
  [03] = 1 -- invalid type
}
local defaultHmiCap = common.setHMIcap(common.vehicleTypeInfoParams.default)
local rpcServiceAckParams = common.getRpcServiceAckParams(defaultHmiCap)
rpcServiceAckParams.systemSoftwareVersion = nil
rpcServiceAckParams.systemHardwareVersion = nil

--[[ Local Functions ]]
local function setHmiCap(pTC)
  local hmiCap = common.cloneTable(defaultHmiCap)
  local systemInfoParams = hmiCap.BasicCommunication.GetSystemInfo.params
  systemInfoParams.systemHardwareVersion = pTC
  return hmiCap
end

--[[ Scenario ]]
for tc, data in common.spairs(tcs) do
  common.Title("TC[" .. string.format("%03d", tc) .. "]")
  common.Title("Preconditions")
  common.Step("Clean environment", common.preconditions)
  local hmiCap = setHmiCap(data)

  common.Title("Test")
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.startWithCustomCap, { hmiCap })
  common.Step("Start RPC Service, Vehicle type data in StartServiceAck", common.startRpcService,
    { rpcServiceAckParams })

  common.Title("Postconditions")
  common.Step("Stop SDL", common.postconditions, { removeCreatedSession })
end
