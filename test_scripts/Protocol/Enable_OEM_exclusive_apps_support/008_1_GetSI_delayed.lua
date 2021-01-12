---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local delay = 3000
local tolerance = 500
local hmiCap = common.setHMIcap(common.vehicleTypeInfoParams.default)
hmiCap.BasicCommunication.GetSystemInfo.mandatory = false
hmiCap.VehicleInfo.GetVehicleType.mandatory = false
local rpcServiceAckParams = common.getRpcServiceAckParams(hmiCap)

--[[ Local Functions ]]
local function delayedStartServiceAck(pStartServiceEvent, pHMICap)
  local ts_req
  local ts_getSI_res
  local ts_getVT_req
  common.hmi.getConnection():ExpectRequest("BasicCommunication.GetSystemInfo")
  :Do(function(_, data)
      ts_req = timestamp()
      local function sendGetSIresp()
        local getSIparams = pHMICap.BasicCommunication.GetSystemInfo.params
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", getSIparams)
        ts_getSI_res = timestamp()
      end
      RUN_AFTER(sendGetSIresp, delay)
    end)
  common.hmi.getConnection():ExpectRequest("VehicleInfo.GetVehicleType")
  :Do(function(_, data)
      ts_getVT_req = timestamp()
      local getVTparams = pHMICap.VehicleInfo.GetVehicleType.params
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", getVTparams)
    end)
  common.startRpcService(rpcServiceAckParams)
  :ValidIf(function()
      local ts_res = timestamp()
      -- delay between receiving of BC.GetSystemInfo and requesting VI.GetVehicleType
      local getVTdelay = ts_getVT_req - ts_getSI_res
      local exp_delay = delay + getVTdelay
      local act_delay = ts_res - ts_req
      common.log("Delay:", act_delay)
      common.hmi.getConnection():RaiseEvent(pStartServiceEvent, "Start event")
      if act_delay < exp_delay - tolerance or act_delay > exp_delay + tolerance then
        return false, "Expected delay: " .. exp_delay .. "ms, actual: " .. act_delay .. "ms"
      end
      return true
    end)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)

common.Title("Test")
common.Step("Start SDL, HMI, connect Mobile, start Session, send StartService", common.startWithExtension,
  { hmiCap, delayedStartServiceAck })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
