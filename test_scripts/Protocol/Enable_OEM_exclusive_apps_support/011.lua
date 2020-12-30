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
local reqParams = {
  protocolVersion = common.setStringBsonValue("5.3.0")
}

--[[ Local Functions ]]
local function getAckParams(pHmiCap)
  local ackParams = common.getRpcServiceAckParams(pHmiCap)
  return ackParams
end

local function getHmiCap(pTC)
  local hmiCap = common.getHmiCap()
  local systemInfoParams = hmiCap.BasicCommunication.GetSystemInfo.params
  systemInfoParams.systemHardwareVersion = pTC
  return hmiCap
end

--[[ Scenario ]]
for tc, data in common.spairs(tcs) do
  common.Title("Preconditions")
  common.Step("Clean environment", common.preconditions)
  local hmiCap = getHmiCap(data)
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.startWithCustomCap, { hmiCap })

  common.Title("TC[" .. string.format("%03d", tc) .. "]")
  local ackParams = getAckParams(hmiCap)
  common.Step("Start RPC Service, Vehicle type data in StartServiceAck", common.startServiceUnprotectedACK,
    { 1, common.serviceType.RPC, reqParams, ackParams })

  common.Title("Postconditions")
  common.Step("Remove mobile session", common.deleteSession)
  common.Step("Stop SDL", common.postconditions)
end

