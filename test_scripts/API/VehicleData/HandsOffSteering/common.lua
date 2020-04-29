---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 6
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 2

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local json = require("modules/json")
local utils = require("user_modules/utils")
local test = require("user_modules/dummy_connecttest")
local events = require('events')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 2

--[[ Local Variables ]]
local m = {}
local hashId = {}

--[[ Shared Functions ]]
m.Title = runner.Title
m.Step = runner.Step
m.getPreloadedPT = actions.sdl.getPreloadedPT
m.setPreloadedPT = actions.sdl.setPreloadedPT
m.registerApp = actions.registerApp
m.registerAppWOPTU = actions.registerAppWOPTU
m.activateApp = actions.activateApp
m.getMobileSession = actions.getMobileSession
m.getHMIConnection = actions.getHMIConnection
m.getParams = actions.app.getParams
m.backupPreloadedPT = actions.sdl.backupPreloadedPT
m.restorePreloadedPT = actions.sdl.restorePreloadedPT
m.cloneTable = utils.cloneTable
m.getConfigAppParams = actions.getConfigAppParams
m.preconditions = actions.preconditions
m.start = actions.start
m.postconditions = actions.postconditions
m.policyTableUpdate = actions.policyTableUpdate
m.getAppsCount = actions.getAppsCount

--[[ Common Functions ]]
function m.precondition()
  m.backupPreloadedPT()
  m.preconditions()
end

--[[ @updatedPreloadedPTFile: Update preloaded file with additional permissions
--! @parameters:
--! pGroups: table with additional updates (optional)
--! @return: none
--]]
function m.updatedPreloadedPTFile(pGroups)
  local pt = m.getPreloadedPT()
  if not pGroups then
    pGroups = {
      rpcs = {
        GetVehicleData = {
          hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
          parameters = { "handsOffSteering" }
        },
        OnVehicleData = {
          hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
          parameters = { "handsOffSteering" }
        },
        SubscribeVehicleData = {
          hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
          parameters = { "handsOffSteering" }
        },
        UnsubscribeVehicleData = {
          hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
          parameters = { "handsOffSteering" }
        }
      }
    }
  end
  pt.policy_table.functional_groupings["NewTestCaseGroup"] = pGroups
  pt.policy_table.app_policies["default"].groups = { "Base-4", "NewTestCaseGroup" }
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  m.setPreloadedPT(pt)
end

--[[ @setHashId: Set hashId which is required during resumption
--! @parameters:
--! pHashId: application hashId
--! pAppId: application number (1, 2, etc.)
--! @return: none
--]]
function m.setHashId(pHashId, pAppId)
  hashId[pAppId] = pHashId
end

--[[ @getHashId: Get hashId of an app which is required during resumption
--! @parameters:
--! pAppId: application number (1, 2, etc.)
--! @return: app's hashId
--]]
function m.getHashId(pAppId)
  return hashId[pAppId]
end

--[[ @getVehicleData: Processing GetVehicleData RPC
--! @parameters:
--! pHandsOffSteering: Vehicle parameter value
--! pAppId: application number (1, 2, etc.)
--! @return: none
--]]
function m.getVehicleData(pHandsOffSteering, pAppId)
  if not pAppId then pAppId = 1 end
  local cid = m.getMobileSession(pAppId):SendRPC("GetVehicleData", { handsOffSteering = true })
  m.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { handsOffSteering = true })
  :Do(function(_, data)
    m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { handsOffSteering = pHandsOffSteering })
  end)
  m.getMobileSession(pAppId):ExpectResponse(cid,
    { success = true, resultCode = "SUCCESS", handsOffSteering = pHandsOffSteering })
end

--[[ @getVDDisallowed: Processing GetVehicleData RPC not allowed by Policy
--! @parameters:
--! pAppId: application number (1, 2, etc.)
--! @return: none
--]]
function m.getVDDisallowed(pAppId)
  if not pAppId then pAppId = 1 end
  local cid = m.getMobileSession(pAppId):SendRPC("GetVehicleData", { handsOffSteering = true })
  m.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData")
  :Times(0)
  m.getMobileSession(pAppId):ExpectResponse(cid, { success = false, resultCode = "DISALLOWED" })
end

--[[ @processRPCSuccess: Processing Subscribe/Unsubscribe RPC on VD
--! @parameters:
--! pRpcName: RPC name
--! pAppId: application number (1, 2, etc.)
--! @return: none
--]]
function m.processRPCSuccess(pRpcName, pAppId)
  if not pAppId then pAppId = 1 end
  local handsOffSteeringResponseData = {
    dataType = "VEHICLEDATA_HANDSOFFSTEERING",
    resultCode = "SUCCESS"
  }
  local cid = m.getMobileSession(pAppId):SendRPC(pRpcName, { handsOffSteering = true })
  m.getHMIConnection():ExpectRequest("VehicleInfo." .. pRpcName, { handsOffSteering = true })
  :Do(function(_, data)
    m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
      { handsOffSteering = handsOffSteeringResponseData })
  end)
  m.getMobileSession(pAppId):ExpectResponse(cid,
    { success = true, resultCode = "SUCCESS", handsOffSteering = handsOffSteeringResponseData })
  m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_, data)
    m.setHashId(data.payload.hashID, pAppId)
  end)
end

--[[ @processRPCHMIInvalidResponse: performs case when HMI did respond with invalid data
--! @parameters:
--! @pRpcName: RPC name
--! @return: none
--]]
function m.processRPCHMIInvalidResponse(pRpcName)
  local cid = m.getMobileSession():SendRPC(pRpcName, { handsOffSteering = true })
  m.getHMIConnection():ExpectRequest("VehicleInfo." .. pRpcName, { handsOffSteering = true })
  :Do(function(_, data)
    m.getHMIConnection():SendResponse(data.id, 123, { }) -- invalid method
  end)
  m.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
  m.getMobileSession():ExpectNotification("OnHashChange") :Times(0)
end

--[[ @processRPCHMIWithoutResponse: performs case when HMI did not respond
--! @parameters:
--! @pRpcName: RPC name
--! @return: none
--]]
function m.processRPCHMIWithoutResponse(pRpcName)
  local cid = m.getMobileSession():SendRPC(pRpcName, { handsOffSteering = true })
  m.getHMIConnection():ExpectRequest("VehicleInfo." .. pRpcName, { handsOffSteering = true })
  :Do(function()
    -- HMI did not respond
  end)
  m.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
  m.getMobileSession():ExpectNotification("OnHashChange") :Times(0)
end

--[[ @processRPCInvalidRequest: performs case when App did requested with invalid data
--! @parameters:
--! @pRpcName: RPC name
--! @return: none
--]]
function m.processRPCInvalidRequest(pRpcName)
  local cid = m.getMobileSession():SendRPC(pRpcName, { handsOffSteering = 123 }) -- invalid data
  m.getHMIConnection():ExpectRequest("VehicleInfo." .. pRpcName) :Times(0)
  m.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA" })
  m.getMobileSession():ExpectNotification("OnHashChange") :Times(0)
end

--[[ @processRPCDisallowed: Processing Subscribe/Unsubscribe RPC on VD not allowed by Policy
--! @parameters:
--! @pRpcName: RPC name
--! pAppId: application number (1, 2, etc.)
--! @return: none
--]]
function m.processRPCDisallowed(pRpcName, pAppId)
  if not pAppId then pAppId = 1 end
  local cid = m.getMobileSession(pAppId):SendRPC(pRpcName, { handsOffSteering = true })
  m.getHMIConnection():ExpectRequest("VehicleInfo." .. pRpcName, { handsOffSteering = true }) :Times(0)
  m.getMobileSession(pAppId):ExpectResponse(cid, { success = false, resultCode = "DISALLOWED" })
  m.getMobileSession(pAppId):ExpectNotification("OnHashChange") :Times(0)
end

--[[ @ignitionOff: IGNITION_OFF sequence
--! @parameters: none
--! @return: none
--]]
function m.ignitionOff()
  config.ExitOnCrash = false
  local timeout = 5000
  local function removeSessions()
    for i = 1, m.getAppsCount() do
      test.mobileSession[i] = nil
    end
  end
  local event = events.Event()
  event.matches = function(event1, event2) return event1 == event2 end
  EXPECT_EVENT(event, "SDL shutdown")
  :Do(function()
      removeSessions()
      StopSDL()
      config.ExitOnCrash = true
    end)
  m.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
      m.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications",{ reason = "IGNITION_OFF" })
      for i = 1, m.getAppsCount() do
        m.getMobileSession(i):ExpectNotification("OnAppInterfaceUnregistered", { reason = "IGNITION_OFF" })
      end
    end)
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
  :Times(m.getAppsCount())
  local isSDLShutDownSuccessfully = false
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLClose")
  :Do(function()
      utils.cprint(35, "SDL was shutdown successfully")
      isSDLShutDownSuccessfully = true
      RAISE_EVENT(event, event)
    end)
  :Timeout(timeout)
  local function forceStopSDL()
    if isSDLShutDownSuccessfully == false then
      utils.cprint(35, "SDL was shutdown forcibly")
      RAISE_EVENT(event, event)
    end
  end
  RUN_AFTER(forceStopSDL, timeout + 500)
end

--[[ @reRegisterAppSuccess: re-register application with SUCCESS resultCode
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pCheckFunc: check function
--! @return: none
--]]
function m.reRegisterAppSuccess(pAppId, pCheckFunc)
  if not pAppId then pAppId = 1 end
  m.getMobileSession(pAppId):StartService(7)
  :Do(function()
    local params = m.cloneTable(m.getParams(pAppId))
    params.hashID = m.getHashId(pAppId)
    local corId = m.getMobileSession(pAppId):SendRPC("RegisterAppInterface", params)
    m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered", {
      application = { appName = m.getParams(pAppId).appName }
    })
    m.getMobileSession(pAppId):ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
    :Do(function()
      m.getMobileSession(pAppId):ExpectNotification("OnPermissionsChange")
    end)
  end)
  pCheckFunc(pAppId)
end

--[[ @onVehicleData: Processing OnVehicleData notification
--! @parameters:
--! pHandsOffSteering: Vehicle parameter value
--! @return: none
--]]
function m.onVehicleData(pHandsOffSteering)
  m.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { handsOffSteering = pHandsOffSteering })
  m.getMobileSession():ExpectNotification("OnVehicleData", { handsOffSteering = pHandsOffSteering })
end

--[[ @unexpectedDisconnect: closing connection
--! @parameters: none
--! @return: none
--]]
function m.unexpectedDisconnect()
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = true })
  :Times(actions.mobile.getAppsCount())
  actions.mobile.disconnect()
  utils.wait(1000)
end

--[[ @connectMobile: create connection
--! @parameters: none
--! @return: none
--]]
function m.connectMobile()
  test.mobileConnection:Connect()
  EXPECT_EVENT(events.connectedEvent, "Connected")
  :Do(function()
      utils.cprint(35, "Mobile connected")
    end)
end

function m.postcondition()
  m.restorePreloadedPT()
  m.postconditions()
end

return m
