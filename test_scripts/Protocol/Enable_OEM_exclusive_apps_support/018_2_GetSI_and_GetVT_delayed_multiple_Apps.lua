---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local delay1 = 2000
local delay2 = 3000
local exp_delay = delay1 + delay2
local tolerance = 500

local hmiCap = common.setHMIcap(common.vehicleTypeInfoParams.default)
  hmiCap.BasicCommunication.GetSystemInfo.delay = delay1
  hmiCap.VehicleInfo.GetVehicleType.delay = delay2

--[[ Local Functions ]]
local function startServiceMultipleApps(pStartEvent)
  local reqParams = { protocolVersion = common.setStringBsonValue("5.3.0") }
  local mobSession = common.getMobileSession()
  local msg = {
    serviceType = common.serviceType.RPC,
    frameType = common.frameType.CONTROL_FRAME,
    frameInfo = common.frameInfo.START_SERVICE,
    sessionId = mobSession,
    encryption = false,
    binaryData = common.bson_to_bytes(reqParams)
  }

  mobSession:Send(msg)
  local ts_req1 = timestamp()
  common.log("MOB->SDL: App1".." StartService(7) " .. common.tableToString(reqParams))

  mobSession:Send(msg)
  local ts_req2 = timestamp()
  common.log("MOB->SDL: App2" .." StartService(7) " .. common.tableToString(reqParams))

local function validateResponse(pData, pts_Req)
  local ts_res = timestamp()
  local act_delay = ts_res - pts_Req
  local actPayload = common.bson_to_table(pData.binaryData)
  common.log("Delay:", act_delay)
  common.log("SDL->MOB: App" ..pData.sessionId.." StartServiceAck(7) " .. common.tableToString(actPayload))
  if act_delay < exp_delay - tolerance or act_delay > exp_delay + tolerance then
    return false, "Expected delay: " .. exp_delay .. "ms, actual: " .. act_delay .. "ms"
  end
    return true
end

mobSession:ExpectControlMessage(common.serviceType.RPC, {
  frameInfo = common.frameInfo.START_SERVICE_ACK,
  encryption = false
})
:ValidIf(function(exp, data)
  if exp.occurences == 1 and data.frameInfo == common.frameInfo.START_SERVICE_ACK then
    return validateResponse(data, ts_req1)
  elseif exp.occurences == 2 and data.frameInfo == common.frameInfo.START_SERVICE_ACK then
    common.getHMIConnection():RaiseEvent(pStartEvent, "Start event")
    return validateResponse(data, ts_req2)
  end
    return false, "Unexpected message have been received"
end)
  :Times(2)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)

common.Title("Test")
common.Step("Start SDL, HMI, connect Mobile, start Session, send StartService", common.startWithExtension,
  { startServiceMultipleApps })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
