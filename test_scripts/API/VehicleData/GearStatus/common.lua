---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 6
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 2
config.application2.registerAppInterfaceParams.syncMsgVersion.majorVersion = 6
config.application2.registerAppInterfaceParams.syncMsgVersion.minorVersion = 2

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local json = require("modules/json")
local utils = require("user_modules/utils")
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
m.backupPreloadedPT = actions.sdl.backupPreloadedPT
m.restorePreloadedPT = actions.sdl.restorePreloadedPT
m.cloneTable = utils.cloneTable
m.getConfigAppParams = actions.getConfigAppParams
m.preconditions = actions.preconditions
m.start = actions.start
m.postconditions = actions.postconditions
m.policyTableUpdate = actions.policyTableUpdate
m.getAppsCount = actions.getAppsCount
m.getParams = actions.app.getParams
m.deleteSession = actions.mobile.deleteSession
m.connectMobile = actions.mobile.connect

m.gearStatusData = {
  userSelectedGear = "NINTH",
  actualGear = "TENTH",
  transmissionType = "MANUAL"
}

m.invalidValue = {
  emptyValue = "",
  invalidType = 12345,
  invalidParamValue = "Invalid parameter value"
}

m.subUnsubResponse = {
  dataType = "VEHICLEDATA_GEARSTATUS",
  resultCode = "SUCCESS"
}

m.prndlData = "PARK"

--[[ Common Functions ]]

--[[ @updatePreloadedPT: Update preloaded file with additional permissions for GearStatus
--! @parameters:
--! pGroups: table with additional updates (optional)
--! @return: none
--]]
function m.updatePreloadedPT(pGroups)
  local pt = m.getPreloadedPT()
  if not pGroups then
    pGroups = {
      rpcs = {
        GetVehicleData = {
          hmi_levels = { "BACKGROUND", "LIMITED", "FULL" },
          parameters = { "gearStatus", "prndl" }
        },
        OnVehicleData = {
          hmi_levels = { "BACKGROUND", "LIMITED", "FULL" },
          parameters = { "gearStatus", "prndl" }
        },
        SubscribeVehicleData = {
          hmi_levels = { "BACKGROUND", "LIMITED", "FULL" },
          parameters = { "gearStatus", "prndl" }
        },
        UnsubscribeVehicleData = {
          hmi_levels = { "BACKGROUND", "LIMITED", "FULL" },
          parameters = { "gearStatus", "prndl" }
        }
      }
    }
  end
  pt.policy_table.functional_groupings["NewTestCaseGroup"] = pGroups
  pt.policy_table.app_policies["default"].groups = { "Base-4", "NewTestCaseGroup" }
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  m.setPreloadedPT(pt)
end

--[[ @precondition: Clean environment and backup sdl_preloaded_pt.json file
--! @parameters: none
--! @return: none
--]]
function m.precondition()
  m.backupPreloadedPT()
  m.preconditions()
  m.updatePreloadedPT()
end

--! @pTUpdateFunc: Policy Table Update with allowed "Base-4" group for application
--! @parameters:
--! tbl: policy table
--! @return: none
function m.pTUpdateFunc(tbl)
  tbl.policy_table.app_policies[m.getParams(1).fullAppID].groups = { "Base-4" }
end

--[[ @setHashId: Set hashId which is required during resumption
--! @parameters:
--! pHashValue: application hashId
--! pAppId: application number (1, 2, etc.)
--! @return: none
--]]
function m.setHashId(pHashValue, pAppId)
  hashId[pAppId] = pHashValue
end

--[[ @getHashId: Get hashId of an app which is required during resumption
--! @parameters:
--! pAppId: application number (1, 2, etc.)
--! @return: app's hashId
--]]
function m.getHashId(pAppId)
  return hashId[pAppId]
end

--[[ @checkParam: Check the absence of unexpected params in GetVehicleData and OnVehicleData on the mobile app side
--! @parameters:
--! pData - parameters for mobile response/notification
--! pRPC - RPC for mobile request/notification
--! @return: true - in case response/notification does not contain unexpected params, otherwise - false
--]]
function m.checkParam(pData, pRPC)
  local count = 0
  for _ in pairs(pData.payload.gearStatus) do
    count = count + 1
  end
  if count ~= 1 then
    return false, "Unexpected params are received in " .. pRPC
  else
    return true
  end
end

--[[ @gearStatus: Clone table with data for use to GetVD and OnVD RPCs
--! @parameters: none
--! @return: table
--]]
function m.gearStatus()
  return utils.cloneTable(m.gearStatusData)
end

--[[ @responseTosubUnsubReq: Clone table with data for use to SubVD and UnsubscribeVD RPCs
--! @parameters: none
--! @return: table
--]]
function m.responseTosubUnsubReq()
  return utils.cloneTable(m.subUnsubResponse)
end

--[[ @getVehicleData: Processing GetVehicleData RPC
--! @parameters:
--! pData: parameters for mobile response
--! pParam: parameters for GetVehicleData RPC
--! @return: none
--]]
function m.getVehicleData(pData, pParam)
  if not pParam then pParam = "gearStatus" end
  local cid = m.getMobileSession():SendRPC("GetVehicleData", { [pParam] = true })
  m.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { [pParam] = true })
  :Do(function(_,data)
    m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { [pParam] = pData })
  end)
  m.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS", [pParam] = pData })
end

--[[ @subUnScribeVD: Processing Subscribe/Unsubscribe RPC
--! @parameters:
--! pRPC: RPC for mobile request
--! pParam: parameters for Subscribe/Unsubscribe RPC
--! pVDType: VehicleDataType value
--! pAppId: application number (1, 2, etc.)
--! @return: none
--]]
function m.subUnScribeVD(pRPC, pParam, pVDType, pAppId)
  if not pParam then pParam = "gearStatus" end
  if not pVDType then pVDType = "VEHICLEDATA_GEARSTATUS" end
  if not pAppId then pAppId = 1 end
  local responseData = {
    dataType = pVDType,
    resultCode = "SUCCESS"
  }
  local cid = m.getMobileSession(pAppId):SendRPC(pRPC, { [pParam] = true })
  m.getHMIConnection():ExpectRequest("VehicleInfo." .. pRPC, { [pParam] = true })
  :Do(function(_, data)
    m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { [pParam] = responseData })
  end)
  m.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS", [pParam] = responseData })
  m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_, data)
    m.setHashId(data.payload.hashID, pAppId)
  end)
end

--[[ @checkResumption: function that checks resume of subscription for two applications
--! @parameters:
--! pFirstApp: true - in case SDL sends VehicleInfo.SubscribeVehicleData_requset to HMI, otherwise - false
--! pAppId: application number (1, 2, etc.)
--! @return: none
--]]
function m.checkResumption(pFirstApp, pAppId)
  if not pAppId then pAppId = 1 end
  local cid = m.getMobileSession(pAppId):SendRPC("SubscribeVehicleData", { gearStatus = true })
  if pFirstApp then
    m.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData", { gearStatus = true })
    :Do(function(_,data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { gearStatus = m.subUnsubResponse })
    end)
  end
  m.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS", gearStatus = m.subUnsubResponse })
  m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_, data)
    m.setHashId(data.payload.hashID, pAppId)
  end)
end

--[[ @processRPCFailure: Processing VD RPCs with ERROR resultCode
--! @parameters:
--! pRPC: RPC for mobile request
--! pResult: result error
--! pValue: value for parameters
--! @return: none
--]]
function m.processRPCFailure(pRPC, pResult, pValue)
  if not pValue then pValue = true end
  local cid = m.getMobileSession():SendRPC(pRPC, { gearStatus = pValue })
  m.getHMIConnection():ExpectRequest("VehicleInfo." .. pRPC):Times(0)
  m.getMobileSession():ExpectResponse(cid, { success = false, resultCode = pResult })
end

--[[ @invalidDataFromHMI: function for check case when HMI did respond with invalid data to VD RPCs
--! @parameters:
--! pRPC: RPC for mobile request
--! pData: data from HMI
--! pParam: parameters from GearStatus structure
--! pValue: value for parameters
--! @return: none
--]]
function m.invalidDataFromHMI(pRPC, pData, pParam, pValue)
  local params = pData
  params[pParam] = pValue
  local cid = m.getMobileSession():SendRPC(pRPC, { gearStatus = true })
  m.getHMIConnection():ExpectRequest("VehicleInfo." ..pRPC, { gearStatus = true })
  :Do(function(_, data)
    m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { gearStatus = params })
  end)
  m.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
end

--[[ @sendOnVehicleData: Processing OnVehicleData RPC
--! @parameters:
--! pData: parameters for the notification
--! pExpTime: number of notifications
--! pParam: parameters for OnVehicleData RPC
--! pAppID: application number (1, 2, etc.)
--! @return: none
--]]
function m.sendOnVehicleData(pData, pExpTime, pParam, pAppID)
  if not pExpTime then pExpTime = 1 end
  if not pParam then pParam = "gearStatus" end
  if not pAppID then pAppID = 1 end
  m.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { [pParam] = pData })
  m.getMobileSession(pAppID):ExpectNotification("OnVehicleData", { [pParam] = pData })
  :Times(pExpTime)
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
      m.deleteSession(i)
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

--[[ @checkResumption_FULL: function that checks HMIlevel to FULL recovery after resumption
--! @parameters: none
--! @return: none
--]]
function m.checkResumption_FULL()
  m.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp", {})
  :Do(function(_, data)
    m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  m.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE" },
    { hmiLevel = "FULL" })
  :Times(2)
end

--[[ @checkResumption_NONE: function that checks HMIlevel to NONE recovery after resumption
--! @parameters: none
--! @return: none
--]]
function m.checkResumption_NONE()
  m.getMobileSession(1):ExpectNotification("OnHMIStatus",{ hmiLevel = "NONE" })
end

--[[ @registerWithResumption: re-register application with SUCCESS resultCode
--! @parameters:
--! pAppId: application number (1, 2, etc.)
--! pLevelCheckFunc: function that checks for HMIlevel recovery after resumption
--! isHMIsubscription: if false SDL resumes SubscribeVehicleData for app2 and does not send VehicleInfo.SubscribeVehicleData request to HMI
--! @return: none
--]]
function m.registerWithResumption(pAppId, pLevelCheckFunc, isHMIsubscription)
  if not pAppId then pAppId = 1 end
  m.getMobileSession(pAppId):StartService(7)
  :Do(function()
    local params = m.cloneTable(m.getConfigAppParams(pAppId))
    params.hashID = m.getHashId(pAppId)
    local corId = m.getMobileSession(pAppId):SendRPC("RegisterAppInterface", params)
    m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered", {
      application = { appName = m.getConfigAppParams(pAppId).appName }
    })
    :Do(function(_, data)
      if true == isHMIsubscription then
        m.getHMIConnection():ExpectRequest( "VehicleInfo.SubscribeVehicleData", { gearStatus = true })
        m.getHMIConnection():SendResponse( data.id, data.method, "SUCCESS", { gearStatus = m.subUnsubResponse } )
      else
        m.getHMIConnection():ExpectRequest( "VehicleInfo.SubscribeVehicleData", { gearStatus = true })
        :Times(0)
      end
    end)
    m.getMobileSession(pAppId):ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
    :Do(function()
      m.getMobileSession(pAppId):ExpectNotification("OnPermissionsChange")
    end)
  end)
  pLevelCheckFunc(pAppId)
end

--[[ @postcondition: Stop SDL and restore sdl_preloaded_pt.json file
--! @parameters: none
--! @return: none
--]]
function m.postcondition()
  m.restorePreloadedPT()
  m.postconditions()
end

return m
