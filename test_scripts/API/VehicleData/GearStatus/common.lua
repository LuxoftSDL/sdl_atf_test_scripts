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
local SDL = require("SDL")
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
m.restorePreloadedPT = actions.sdl.restorePreloadedPT
m.cloneTable = utils.cloneTable
m.getConfigAppParams = actions.getConfigAppParams
m.start = actions.start
m.policyTableUpdate = actions.policyTableUpdate
m.getAppsCount = actions.getAppsCount
m.getParams = actions.app.getParams
m.deleteSession = actions.mobile.deleteSession
m.connectMobile = actions.mobile.connect
m.wait = utils.wait
m.postconditions = actions.postconditions

local gearStatusData = {
  userSelectedGear = "NINTH",
  actualGear = "TENTH",
  transmissionType = "MANUAL"
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
          hmi_levels = { "BACKGROUND", "LIMITED", "FULL", "NONE" },
          parameters = { "gearStatus", "prndl" }
        },
        OnVehicleData = {
          hmi_levels = { "BACKGROUND", "LIMITED", "FULL", "NONE" },
          parameters = { "gearStatus", "prndl" }
        },
        SubscribeVehicleData = {
          hmi_levels = { "BACKGROUND", "LIMITED", "FULL", "NONE" },
          parameters = { "gearStatus", "prndl" }
        },
        UnsubscribeVehicleData = {
          hmi_levels = { "BACKGROUND", "LIMITED", "FULL", "NONE" },
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

--[[ @preconditions: Clean environment and optional backup and update of sdl_preloaded_pt.json file
--! @parameters:
--! isPreloadedUpdate: if true then sdl_preloaded_pt.json file will be updated, otherwise - false
--! @return: none
--]]
function m.preconditions(isPreloadedUpdate)
  if isPreloadedUpdate == nil then isPreloadedUpdate = true end
  actions.preconditions()
  if isPreloadedUpdate == true then
    m.updatePreloadedPT()
  end
end

--! @pTUpdateFunc: Policy Table Update with allowed "Base-4" group for application
--! @parameters:
--! tbl: policy table
--! @return: none
function m.pTUpdateFunc(tbl)
  local VDgroup = {
    rpcs = {
      GetVehicleData = {
        hmi_levels = { "BACKGROUND", "FULL", "LIMITED" },
        parameters = { "gps" }
      },
      SubscribeVehicleData = {
        hmi_levels = { "BACKGROUND", "FULL", "LIMITED" },
        parameters = { "gps" }
      },
      UnsubscribeVehicleData = {
        hmi_levels = { "BACKGROUND", "FULL", "LIMITED" },
        parameters = { "gps" }
      },
      OnVehicleData = {
        hmi_levels = { "BACKGROUND", "FULL", "LIMITED" },
        parameters = { "gps" }
      }
    }
  }
  tbl.policy_table.functional_groupings.NewVehicleDataGroup = VDgroup
  tbl.policy_table.app_policies[m.getParams().fullAppID].groups = { "Base-4", "NewVehicleDataGroup" }
end

--[[ @setHashId: Set hashId which is required during resumption
--! @parameters:
--! pHashValue: application's hashId
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
--! @return: true - in case response/notification does not contain unexpected params, otherwise - false with error message
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
--! @return: table for GetVD and OnVD
--]]
function m.getGearStatusParams()
  return utils.cloneTable(gearStatusData)
end

--[[ @responseTosubUnsubReq: Clone table with data for use in SubscribeVD and UnsubscribeVD RPCs
--! @parameters: none
--! @return: table for SubscribeVD and UnsubscribeV
--]]
function m.responseTosubUnsubReq()
  return utils.cloneTable(m.subUnsubResponse)
end

--[[ @setValue: Set value for params from `gearStatus` structure
--! @parameters:
--! pParam: parameters from `gearStatus` structure
--! pValue: value for parameters from the `gearStatus` structure
--! @return: table for GetVD and OnVD
--]]
function m.setValue(pParam, pValue)
  local param = m.gearStatus()
  param[pParam] = pValue
  return param
end

--[[ @getVehicleData: Processing GetVehicleData RPC
--! @parameters:
--! pData: parameters for GetVehicleData response
--! pParam: parameter for GetVehicleData request
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

--[[ @subUnScribeVD: Processing Subscribe/UnsubscribeVehicleData RPC
--! @parameters:
--! pRPC: RPC for mobile request
--! pParam: parameters for Subscribe/UnsubscribeVehicleData RPC
--! pVDType: VehicleDataType value
--! isRequestOnHMIExpected: true or omitted - in case VehicleInfo.Subscribe/UnsubscribeVehicleData_request on HMI is expected, otherwise - false
--! pAppId: application number (1, 2, etc.)
--! @return: none
--]]
function m.subUnScribeVD(pRPC, pParam, pVDType, isRequestOnHMIExpected, pAppId)
  if not pParam then pParam = "gearStatus" end
  if not pVDType then pVDType = "VEHICLEDATA_GEARSTATUS" end
  if isRequestOnHMIExpected == nil then isRequestOnHMIExpected = true end
  if not pAppId then pAppId = 1 end
  local responseData = {
    dataType = pVDType,
    resultCode = "SUCCESS"
  }
  local cid = m.getMobileSession(pAppId):SendRPC(pRPC, { [pParam] = true })
  if isRequestOnHMIExpected then
    m.getHMIConnection():ExpectRequest("VehicleInfo." .. pRPC, { [pParam] = true })
    :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { [pParam] = responseData })
    end)
  else
    m.getHMIConnection():ExpectRequest("VehicleInfo." .. pRPC):Times(0)
  end
  m.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS", [pParam] = responseData })
  m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_, data)
    m.setHashId(data.payload.hashID, pAppId)
  end)
end

--[[ @processRPCFailure: Processing VD RPCs with ERROR resultCode
--! @parameters:
--! pRPC: RPC for mobile request
--! pResult: Result code for mobile response
--! pValue: value for a request parameter
--! @return: none
--]]
function m.processRPCFailure(pRPC, pResult, pValue)
  if not pValue then pValue = true end
  local cid = m.getMobileSession():SendRPC(pRPC, { gearStatus = pValue })
  m.getHMIConnection():ExpectRequest("VehicleInfo." .. pRPC):Times(0)
  m.getMobileSession():ExpectResponse(cid, { success = false, resultCode = pResult })
end

--[[ @invalidDataFromHMI: function for check case when HMI does respond with invalid data to VD RPCs
--! @parameters:
--! pRPC: RPC for mobile request
--! pData: data for HMI response
--! pParam: parameter name from GearStatus structure
--! pValue: value for a parameter from GearStatus structure
--! @return: none
--]]
function m.invalidDataFromHMI(pRPC, pData, pParam, pValue)
  local params = pData
  if pParam then params[pParam] = pValue end
  local cid = m.getMobileSession():SendRPC(pRPC, { gearStatus = true })
  m.getHMIConnection():ExpectRequest("VehicleInfo." ..pRPC, { gearStatus = true })
  :Do(function(_, data)
    m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { gearStatus = params })
  end)
  m.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
end

--[[ @sendOnVehicleData: Processing OnVehicleData RPC
--! @parameters:
--! pData: parameter data for the notification
--! pExpTime: expected number of notifications
--! pParam: parameter for OnVehicleData RPC
--! pAppID: application number (1, 2, etc.)
--! @return: none
--]]
function m.sendOnVehicleData(pData, pExpTime, pParam, pAppId)
  if not pExpTime then pExpTime = 1 end
  if not pAppId then pAppId = 1 end
  if not pParam then pParam = "gearStatus" end
  m.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { [pParam] = pData })
  m.getMobileSession(pAppId):ExpectNotification("OnVehicleData", { [pParam] = pData })
  :Times(pExpTime)
end

--[[ @ignitionOff: IGNITION_OFF sequence
--! @parameters: none
--! @return: none
--]]
function m.ignitionOff()
  local isOnSDLCloseSent = false
  m.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
    m.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "IGNITION_OFF" })
    m.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLClose")
    :Do(function()
      isOnSDLCloseSent = true
      SDL.DeleteFile()
    end)
    :Times(AtMost(1))
  end)
  m.wait(3000)
  :Do(function()
    if isOnSDLCloseSent == false then m.cprint(35, "BC.OnSDLClose was not sent") end
    if SDL:CheckStatusSDL() == SDL.RUNNING then SDL:StopSDL() end
    for i = 1, m.getAppsCount() do
      m.deleteSession(i)
    end
  end)
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

--[[ @registerAppWithResumption: Successful app registration with resumption
--! @parameters:
--! pAppId: application number (1, 2, etc.)
--! pLevelCheckFunc: function for expectation of HMI level related messages
--! isHMIsubscription: if true VD.SubscribeVehicleData request is expected on HMI, otherwise - not expected
--! @return: none
--]]
function m.registerAppWithResumption(pAppId, isHMIsubscription)
  if not pAppId then pAppId = 1 end
  m.getMobileSession(pAppId):StartService(7)
  :Do(function()
    m.getConfigAppParams(pAppId).hashID = m.getHashId(pAppId)
    local corId = m.getMobileSession(pAppId):SendRPC("RegisterAppInterface", m.getConfigAppParams(pAppId))
    m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered", {
      application = { appName = m.getConfigAppParams(pAppId).appName }
    })
    :Do(function()
      if true == isHMIsubscription then
        m.getHMIConnection():ExpectRequest( "VehicleInfo.SubscribeVehicleData", { gearStatus = true })
        :Do(function(_, data)
          m.getHMIConnection():SendResponse( data.id, data.method, "SUCCESS", { gearStatus = m.subUnsubResponse } )
        end)
      else
        m.getHMIConnection():ExpectRequest( "VehicleInfo.SubscribeVehicleData"):Times(0)
      end
    end)
    m.getMobileSession(pAppId):ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
    :Do(function()
      m.getMobileSession(pAppId):ExpectNotification("OnPermissionsChange")
    end)
  end)
end

return m
