---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local delay = 3000
local tolerance = 500
local hmiCap = common.setHMIcap(common.vehicleTypeInfoParams.default)
hmiCap.BasicCommunication.GetSystemInfo.delay = delay
local rpcServiceAckParams = common.getRpcServiceAckParams(hmiCap)

--[[ Local Functions ]]
local function delayedStartServiceAck(pStartServiceEvent)
  local ts_req = timestamp()
  common.startRpcService(rpcServiceAckParams)
  :ValidIf(function()
      local ts_res = timestamp()
      local act_delay = ts_res - ts_req
      common.log("Delay:", act_delay)
      common.hmi.getConnection():RaiseEvent(pStartServiceEvent, "Start event")
      if act_delay < delay - tolerance or act_delay > delay + tolerance then
        return false, "Expected delay: " .. delay .. "ms, actual: " .. act_delay .. "ms"
      end
      return true
    end)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { hmiCap })
common.Step("Ignition off", common.ignitionOff)

common.Title("Test")
common.Step("Start SDL, HMI, connect Mobile, start Session, send StartService", common.startWithExtension,
  { hmiCap, delayedStartServiceAck })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
