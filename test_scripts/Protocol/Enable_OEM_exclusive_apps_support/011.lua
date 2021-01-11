---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local tcs = {
  [01] = string.rep("a", 500), --max value
  [02] = string.rep("a", 1) -- min value
}

--[[ Local Functions ]]
local function setHmiCap(pTC)
  local hmiCap = common.setHMIcap(common.vehicleTypeInfoParams.default)
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
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { hmiCap })

  common.Title("Test")
  local rpcServiceAckParams = common.getRpcServiceAckParams(hmiCap)
  common.Step("Start RPC Service, Vehicle type data in StartServiceAck",
    common.startRpcService, { rpcServiceAckParams })

  common.Title("Postconditions")
  common.Step("Stop SDL", common.postconditions)
end

