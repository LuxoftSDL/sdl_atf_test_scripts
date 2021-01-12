---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local delay1 = 2000
local delay2 = 3000
local tolerance = 500

--[[ Local Functions ]]
local function start()
  local hmiCap = common.setHMIcap(common.vehicleTypeInfoParams.default)
  local rpcServiceAckParams = common.getRpcServiceAckParams(hmiCap)
  hmiCap.BasicCommunication.GetSystemInfo.delay = delay1
  hmiCap.VehicleInfo.GetVehicleType.delay = delay2
  local event = common.run.createEvent()
  common.init.SDL()
  :Do(function()
      common.init.HMI()
      :Do(function()
          common.init.connectMobile()
          :Do(function()
            local ts_req = timestamp()
            common.startRpcService(rpcServiceAckParams)
            :ValidIf(function()
                local ts_res = timestamp()
                local exp_delay = delay1 + delay2
                local act_delay = ts_res - ts_req
                common.log("Delay:", act_delay)
                common.hmi.getConnection():RaiseEvent(event, "Start event")
                if act_delay < exp_delay - tolerance or act_delay > exp_delay + tolerance then
                  return false, "Expected delay: " .. exp_delay .. "ms, actual: " .. act_delay .. "ms"
                end
                return true
              end)
            end)
          common.init.HMI_onReady(hmiCap)
        end)
    end)
  return common.hmi.getConnection():ExpectEvent(event, "Start event")
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)

common.Title("Test")
common.Step("Start SDL, HMI, connect Mobile, start Session, send StartService", start)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
