---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 4

--[[ Local Variables ]]
local delay = 3000
local toleranceForRAI = 500
local toleranceForAck = 100
local hmiCap = common.setHMIcap(common.vehicleTypeInfoParams.default)
local hmiCapDelayed = common.cloneTable(hmiCap)
hmiCapDelayed.BasicCommunication.GetSystemInfo.delay = delay

--[[ Local Functions ]]
local function delayedRAIresp(pStartServiceEvent)
  local session = common.getMobileSession()
  local ts_req = timestamp()
  session:StartService(common.serviceType.RPC)
  :ValidIf(function()
      local ts_res = timestamp()
      local act_delay = ts_res - ts_req
      common.log("Delay ack:", act_delay)
      if act_delay > toleranceForAck then
        return false, "StartServiceAck is expected right after StartService request, actual delay: " ..
        act_delay .. "ms"
      end
      return true
    end)
  :Do(function()
      local ts_req_RAI = timestamp()
      common.registerAppEx(common.vehicleTypeInfoParams.default)
      :ValidIf(function()
          local ts_res_RAI = timestamp()
          local act_delay = ts_res_RAI - ts_req_RAI
          common.log("Delay RAI:", act_delay)
          common.hmi.getConnection():RaiseEvent(pStartServiceEvent, "Start event")
          if act_delay < delay - toleranceForRAI or act_delay > delay + toleranceForRAI then
            return false, "Expected delay: " .. delay .. "ms, actual: " .. act_delay .. "ms"
          end
          return true
        end)
    end)
  common.hmi.getConnection():ExpectRequest("VehicleInfo.GetVehicleType"):Times(0)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { hmiCap })
common.Step("Ignition off", common.ignitionOff)

common.Title("Test")
common.Step("Start SDL, HMI, connect Mobile, start Session, send StartService, RAI", common.startWithExtension,
  { hmiCapDelayed, delayedRAIresp })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
