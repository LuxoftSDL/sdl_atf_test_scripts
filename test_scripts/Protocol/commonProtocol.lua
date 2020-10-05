---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local ssl = require("test_scripts/Security/SSLHandshakeFlow/common")
local constants = require("protocol_handler/ford_protocol_constants")
local runner = require('user_modules/script_runner')
local utils = require('user_modules/utils')
local events = require("events")
local bson = require('bson4lua')

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 5

--[[ Variables ]]
local common = ssl

common.events      = events
common.frameInfo   = constants.FRAME_INFO
common.frameType   = constants.FRAME_TYPE
common.serviceType = constants.SERVICE_TYPE
common.getDeviceName = utils.getDeviceName
common.getDeviceMAC = utils.getDeviceMAC
common.isFileExist = utils.isFileExist
common.cloneTable = utils.cloneTable
common.testSettings = runner.testSettings
common.Title = runner.Title
common.Step = runner.Step

common.bsonType = {
    DOUBLE   = 0x01,
    STRING   = 0x02,
    DOCUMENT = 0x03,
    ARRAY    = 0x04,
    BOOLEAN  = 0x08,
    INT32    = 0x10,
    INT64    = 0x12
}

--[[ Tests Configuration ]]
runner.testSettings.isSelfIncluded = false
if not common.isFileExist("lib/bson4lua.so") then
  runner.skipTest("'bson4lua' library is not available in ATF")
  runner.Step("Skipping test")
  return
end

--[[ Functions ]]
function common.startServiceProtectedACK(pAppId, pServiceId, pRequestPayload, pResponsePayload)
    local mobSession = common.getMobileSession(pAppId)
    mobSession:StartSecureService(pServiceId, bson.to_bytes(pRequestPayload))
    mobSession:ExpectControlMessage(pServiceId, {
      frameInfo = common.frameInfo.START_SERVICE_ACK,
      encryption = true
    })
    :ValidIf(function(_, data)
        local actPayload = bson.to_table(data.binaryData)
        return compareValues(pResponsePayload, actPayload, "binaryData")
    end)

    if pServiceId == 7 then
        mobSession:ExpectHandshakeMessage()
    elseif pServiceId == 11 then
        common.getHMIConnection():ExpectRequest("Navigation.SetVideoConfig")
        :Do(function(_, data)
            common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
        end)
    end
end

function common.startServiceProtectedNACK(pAppId, pServiceId, pRequestPayload, pResponsePayload)
    local mobSession = common.getMobileSession(pAppId)
    mobSession:StartSecureService(pServiceId, bson.to_bytes(pRequestPayload))
    mobSession:ExpectControlMessage(pServiceId, {
        frameInfo = common.frameInfo.START_SERVICE_NACK,
        encryption = false
    })
    :ValidIf(function(_, data)
        local actPayload = bson.to_table(data.binaryData)
        return compareValues(pResponsePayload, actPayload, "binaryData")
    end)
end

function common.startServiceUnprotectedNACK(pAppId, pServiceId, pRequestPayload, pResponsePayload)
    local mobSession = common.getMobileSession(pAppId)
    local msg = {
        serviceType = pServiceId,
        frameType = constants.FRAME_TYPE.CONTROL_FRAME,
        frameInfo = constants.FRAME_INFO.START_SERVICE,
        sessionId = mobSession,
        encryption = false,
        binaryData = bson.to_bytes(pRequestPayload)
    }
    mobSession:Send(msg)
    mobSession:ExpectControlMessage(pServiceId, {
        frameInfo = common.frameInfo.START_SERVICE_NACK,
        encryption = false
    })
    :ValidIf(function(_, data)
        local actPayload = bson.to_table(data.binaryData)
        return compareValues(pResponsePayload, actPayload, "binaryData")
    end)
end

function common.ptuFailedNACK(pAppId, pServiceId, pRequestPayload, pResponsePayload, pExtentionFunc)
    if pExtentionFunc then pExtentionFunc() end
    common.startServiceProtectedNACK(pAppId, pServiceId, pRequestPayload, pResponsePayload)
    common.getMobileSession():ExpectHandshakeMessage()
    :Times(0)
    local function ptUpdate(pTbl)
        pTbl.policy_table.module_config.notifications_per_minute_by_priority = nil
    end
    local expNotificationFunc = function()
        common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData")
        :Times(0)
    end
    common.isPTUStarted()
    :Do(function()
        common.policyTableUpdate(ptUpdate, expNotificationFunc)
    end)
  end

function common.startSecureServiceTimeNotProvided(pAppId, pServiceId, pRequestPayload, pResponsePayload, pExtentionFunc)
    if pExtentionFunc then pExtentionFunc() end

    local event = events.Event()
    event.level = 3
    event.matches = function(_, data)
        return data.method == "BasicCommunication.GetSystemTime"
    end
    common.getHMIConnection():ExpectEvent(event, "Expect GetSystemTime")
    :Do(function(_, data)
        common.getHMIConnection():SendError(data.id, data.method, "DATA_NOT_AVAILABLE", "Time is not provided")
    end)

    common.startServiceProtectedNACK(pAppId, pServiceId, pRequestPayload, pResponsePayload)
end

return common
