---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL is able to provide vehicle type data for each app that requests StartService and
--  RAI via 5 protocol after all vehicle type data have been received in case StartService is requested before receiving
--  BC.GetSystemInfo and VI.GetVehicleType responses
--
-- Steps:
-- 1. SDL requests BC.GetSystemInfo and VI.GetVehicleType to HMI after start
-- 2. App1 and App2 request StartService(RPC) via 5th protocol
-- SDL does:
--  - Postpone the sending of StartServiceAcks before receiving of BC.GetSystemInfo and VI.GetVehicleType responses
-- 3. HMI responds with delay to BC.GetSystemInfo and to VI.GetVehicleType requests
-- SDL does:
--  - Send StartServiceAcks after receiving VI.GetVehicleType and BC.GetSystemInfo responses with all vehicle type data
--     received from HMI to app1 and app2
-- 4. App1 and App2 request RAI after receiving StartServiceAck
-- SDL does:
--  - Provide all vehicle type data received from HMI in RAI response to the app1 and app2
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local delay1 = 2000
local delay2 = 3000
local hmiCap = common.setHMIcap(common.vehicleTypeInfoParams.default)

--[[ Local Functions ]]
local function delayedStartServiceAckMultipleApps(pHmiCap, pDelayGetSI, pDelayGetVT)
  local rpcServiceAckParams = common.getRpcServiceAckParams(pHmiCap)
  local getSIparams = pHmiCap.BasicCommunication.GetSystemInfo.params
  local getVTparams = pHmiCap.VehicleInfo.GetVehicleType.params
  pHmiCap.VehicleInfo.GetVehicleType = nil
  pHmiCap.BasicCommunication.GetSystemInfo = nil

  local ts_get_si
  local ts_get_vt

  common.init.HMI_onReady(pHmiCap)

  common.hmi.getConnection():ExpectRequest("BasicCommunication.GetSystemInfo")
  :Do(function(_, data)
      local function response()
        ts_get_si = timestamp()
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", getSIparams)
      end
      common.run.runAfter(response, pDelayGetSI)
    end)

  local times_GetVT = 1
  if pDelayGetVT == -1 then times_GetVT = 0 end
  common.hmi.getConnection():ExpectRequest("VehicleInfo.GetVehicleType")
  :Do(function(_, data)
      local function response()
        ts_get_vt = timestamp()
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", getVTparams)
      end
      if pDelayGetVT ~= -1 then common.run.runAfter(response, pDelayGetVT) end
    end)
   :Times(times_GetVT)

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
  common.log("MOB->SDL: App1".." StartService(7)", reqParams)

  mobSession:Send(msg)
  common.log("MOB->SDL: App2" .." StartService(7)", reqParams)

  local function validateResponse(pData)
    local actPayload = common.bson_to_table(pData.binaryData)
    common.log("SDL->MOB: App" ..pData.sessionId.." StartServiceAck(7)", actPayload)
    if ts_get_si == nil then
      return false, "StartServiceAck received before receiving of GetSystemInfo from HMI"
    end
    if ts_get_vt == nil and pDelayGetVT ~= -1 then
      return false, "StartServiceAck received before receiving of GetVehicleType from HMI"
    end
      return compareValues(rpcServiceAckParams, actPayload, "binaryData")
  end

  mobSession:ExpectControlMessage(common.serviceType.RPC, {
    frameInfo = common.frameInfo.START_SERVICE_ACK,
    encryption = false
  })
  :ValidIf(function(exp, data)
    if exp.occurences == 1 and data.frameInfo == common.frameInfo.START_SERVICE_ACK then
      return validateResponse(data)
    elseif exp.occurences == 2 and data.frameInfo == common.frameInfo.START_SERVICE_ACK then
      return validateResponse(data)
    end
      return false, "Unexpected message have been received"
  end)
    :Times(2)
end

local function start()
  local function check()
    delayedStartServiceAckMultipleApps(hmiCap, delay1, delay2)
  end
  common.startWithExtension(check)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)

common.Title("Test")
common.Step("Start SDL, HMI, connect Mobile, start Session, send StartService", start)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
