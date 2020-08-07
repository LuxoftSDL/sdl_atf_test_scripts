---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")
local json = require("modules/json")
local runner = require('user_modules/script_runner')
local rc = require('user_modules/sequences/remote_control')
local SDL = require('SDL')
local color = require("user_modules/consts").color

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.application1.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }
config.application2.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }
config.application1.registerAppInterfaceParams.isMediaApplication = true
config.application2.registerAppInterfaceParams.isMediaApplication = false

--[[ Variables ]]
local m = {}
m.modules = { "RADIO", "CLIMATE", "SEAT", "AUDIO", "LIGHT", "HMI_SETTINGS" }
m.hashId = {}
local modulesWithSubscription = { }
local messageStatusAboutDefaultModuleId = false

-- [[ Shared Functions ]]
m.Title = runner.Title
m.Step = runner.Step
m.postconditions = actions.postconditions
m.start = rc.rc.start
m.registerAppWOPTU = actions.registerAppWOPTU
m.activateApp = actions.activateApp
m.cloneTable = utils.cloneTable
m.wait = utils.wait
m.tableToString = utils.tableToString
m.postconditions = actions.postconditions
m.getHMIConnection = actions.hmi.getConnection
m.getMobileSession = actions.mobile.getSession
m.getHMIAppId = actions.app.getHMIId
m.mobileConnect = actions.mobile.connect
m.getConfigAppParams =  actions.getConfigAppParams
m.setHMIAppId = actions.app.setHMIId
m.isTableEqual = utils.isTableEqual
m.isTableContains = utils.isTableContains
m.fail = actions.run.fail
m.getActualModuleIVData = rc.state.getActualModuleIVData

--[[ General configuration ]]
local state = rc.state.buildDefaultActualModuleState(rc.predefined.getRcCapabilities())
rc.state.initActualModuleStateOnHMI(state)

-- [[ Common Functions ]]
local function boolToTimes(isTrue)
  if isTrue then
    return 1
  end
  return 0
end

local function setSubscriptionModuleStatus(pModuleType, pModuleId, isSubscribed)
  local newValue = {
    moduleType = pModuleType,
    moduleId = pModuleId
  }

  if m.isTableContains(modulesWithSubscription, newValue) == true and isSubscribed == false then
    for key, value in pairs(modulesWithSubscription) do
      if m.isTableEqual(value, newValue) then
        table.remove(modulesWithSubscription, key)
      end
    end
  elseif m.isTableContains(modulesWithSubscription, newValue) == false and isSubscribed == true then
    table.insert(modulesWithSubscription, newValue)
  end
end

function  m.GetInteriorVehicleData(pModuleType, pModuleId, isSubscribe, pIsIVDataCached, hashChangeExpectTimes, pAppId)
  pAppId = pAppId or 1
  local rpc = "GetInteriorVehicleData"
  if pIsIVDataCached == nil then pIsIVDataCached = false end

  local moduleId = pModuleId or m.getModuleId(pModuleType,  1)
  local mobileRequestParams = m.cloneTable(rc.rpc.getAppRequestParams(rpc, pModuleType, pModuleId, isSubscribe))

  local hmiRequestParams = rc.rpc.getHMIRequestParams(rpc, pModuleType, moduleId, pAppId, isSubscribe)
  if hashChangeExpectTimes == 0 then hmiRequestParams.subscribe = nil end

  local cid = m.getMobileSession(pAppId):SendRPC(rc.rpc.getAppEventName(rpc), mobileRequestParams)
  m.getHMIConnection():ExpectRequest(rc.rpc.getHMIEventName(rpc), hmiRequestParams)
  :Times(boolToTimes(not pIsIVDataCached))
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
        rc.rpc.getHMIResponseParams(rpc, pModuleType, moduleId, isSubscribe))
    end)
  m.getMobileSession(pAppId):ExpectResponse(cid,
    rc.rpc.getAppResponseParams(rpc, true, "SUCCESS", pModuleType, moduleId, isSubscribe))
  :Do(function()
      setSubscriptionModuleStatus(pModuleType, moduleId, isSubscribe)
    end)

  m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_,data)
      m.hashId[pAppId] = data.payload.hashID
    end)
  :Times(hashChangeExpectTimes or 1)
end

function m.getModuleId(pModuleType, pModuleIdNumber)
  local out = rc.predefined.getModuleControlData(pModuleType, 1)
  if pModuleIdNumber == 1 or nil then
    return out.moduleId
  else
    local actualData = rc.state.getActualModuleStateOnHMI()
    for key, value in pairs(actualData[pModuleType]) do
      if key ~= out.moduleId then
        return value.data.moduleId
      end
    end
  end
  if messageStatusAboutDefaultModuleId == false then
    utils.cprint(color.magenta, "There is only one moduleId for RADIO, LIGHT, HMI_SETTINGS." ..
      "\nChecking default moduleId for these module types." )
    messageStatusAboutDefaultModuleId = true
  end
  return out.moduleId
end

function m.onInteriorVD(pModuleType, pModuleId, pHasSubscription, pAppId)
  if pHasSubscription == nil then pHasSubscription = true end
  rc.rc.isSubscribed(pModuleType, pModuleId or m.getModuleId(pModuleType, 1), pAppId, pHasSubscription)
end

local function getRCAppConfig(pPt)
  if pPt then
    local out = utils.cloneTable(pPt.policy_table.app_policies.default)
    out.moduleType = rc.data.getRcModuleTypes()
    out.groups = { "Base-4", "RemoteControl" }
    out.AppHMIType = { "REMOTE_CONTROL" }
    return out
  else
    return {
      keep_context = false,
      steal_focus = false,
      priority = "NONE",
      default_hmi = "NONE",
      moduleType = rc.data.getRcModuleTypes(),
      groups = { "Base-4", "RemoteControl" },
      AppHMIType = { "REMOTE_CONTROL" }
    }
  end
end

local function updatePreloadedPT(pCountOfRCApps)
  if not pCountOfRCApps then pCountOfRCApps = 2 end
  local preloadedTable = actions.sdl.getPreloadedPT()
  preloadedTable.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  preloadedTable.policy_table.functional_groupings["RemoteControl"].rpcs.OnRCStatus = {
    hmi_levels = { "FULL", "BACKGROUND", "LIMITED", "NONE" }
  }
  for i = 1, pCountOfRCApps do
    local appId = config["application" .. i].registerAppInterfaceParams.fullAppID
    preloadedTable.policy_table.app_policies[appId] = getRCAppConfig(preloadedTable)
    preloadedTable.policy_table.app_policies[appId].AppHMIType = nil
  end
  actions.sdl.setPreloadedPT(preloadedTable)
end

function m.preconditions(isPreloadedUpdate, pCountOfRCApps)
  if isPreloadedUpdate == nil then isPreloadedUpdate = true end
  actions.preconditions()
  if isPreloadedUpdate == true then
    updatePreloadedPT(pCountOfRCApps)
  end
end

function m.reRegisterApp(pAppId, pCheckResumptionData, pCheckResumptionHMILevel, pResultCode)
  if not pAppId then pAppId = 1 end
  if not pResultCode then pResultCode = "SUCCESS" end
  local mobSession = actions.mobile.createSession(pAppId)
  mobSession:StartService(7)
  :Do(function()
      local params = m.cloneTable(m.getConfigAppParams(pAppId))
      params.hashID = m.hashId[pAppId]
      local corId = mobSession:SendRPC("RegisterAppInterface", params)
      m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered", {
          application = { appName = m.getConfigAppParams(pAppId).appName }
        })
      :Do(function(_, data)
          m.setHMIAppId(data.params.application.appID, pAppId)
        end)
      mobSession:ExpectResponse(corId, { success = true, resultCode = pResultCode })
    end)
  pCheckResumptionData()
  pCheckResumptionHMILevel(pAppId)
end

function m.resumptionFullHMILevel(pAppId)
  m.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp", { appID = m.getHMIAppId(pAppId) })
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, "BasicCommunication.ActivateApp", "SUCCESS", {})
    end)
  m.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
    { hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE" })
  :Times(2)
end

function m.checkModuleResumptionData(pModuleType, pModuleId)
  local requestParams = {
    moduleType = pModuleType,
    subscribe = true,
    moduleId = pModuleId
  }
  m.getHMIConnection():ExpectRequest("RC.GetInteriorVehicleData", requestParams)
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
        { moduleData = m.getActualModuleIVData(pModuleType, pModuleId)})
    end)
end

function m.mobileDisconnect()
  local actualModules = { }
  m.getHMIConnection():ExpectRequest(rc.rpc.getHMIEventName("GetInteriorVehicleData", { subscribe = false }))
  :Do(function(exp,data)
      actualModules[exp.occurences] = {
        moduleType = data.params.moduleType,
        moduleId = data.params.moduleId
      }
      if exp.occurences == #modulesWithSubscription then
        if m.isTableEqual(actualModules, modulesWithSubscription) == false then
          local errorMessage = "Subscription is removed not for all modules.\n" ..
            "Actual result:" .. m.tableToString(actualModules) .. "\n" ..
            "Expected result:" .. m.tableToString(modulesWithSubscription) .."\n"
          return false, errorMessage
        end
      end
      return true
    end)
  :Times(#modulesWithSubscription)
  actions.mobile.disconnect()
end

function m.ignitionOff()
  local isOnSDLCloseSent = false
  local actualModules = { }
  m.getHMIConnection():ExpectRequest(rc.rpc.getHMIEventName("GetInteriorVehicleData", { subscribe = false }))
  :Do(function(exp,data)
      actualModules[exp.occurences] = {
        moduleType = data.params.moduleType,
        moduleId = data.params.moduleId
      }
      if exp.occurences == #modulesWithSubscription then
        if m.isTableEqual(actualModules, modulesWithSubscription) == false then
          local errorMessage = "Subscription is removed not for all modules.\n" ..
            "Actual result:" .. m.tableToString(actualModules) .. "\n" ..
            "Expected result:" .. m.tableToString(modulesWithSubscription) .."\n"
          return false, errorMessage
        end
      end
      return true
    end)
  :Times(#modulesWithSubscription)
  m.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
    m.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "IGNITION_OFF" })
    m.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLClose")
    :Do(function()
      isOnSDLCloseSent = true
      SDL.DeleteFile()
    end)
  end)
  m.wait(3000)
  :Do(function()
    if isOnSDLCloseSent == false then m.cprint(color.magenta, "BC.OnSDLClose was not sent") end
    for i = 1, actions.mobile.getAppsCount() do
      actions.mobile.deleteSession(i)
    end
    StopSDL()
  end)
end

function m.reRegisterApps(pCheckResumptionData, pResultCode1stApp, pResultCode2ndApp)
  if not pResultCode1stApp then pResultCode1stApp = "SUCCESS" end
  if not pResultCode2ndApp then pResultCode2ndApp = "SUCCESS" end

  local requestParams1 = m.cloneTable(m.getConfigAppParams(1))
  requestParams1.hashID = m.hashId[1]

  local requestParams2 = m.cloneTable(m.getConfigAppParams(2))
  requestParams2.hashID = m.hashId[2]

  m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered")
  :Do(function(exp, d1)
      if d1.params.appName == m.getConfigAppParams(1).appName then
        m.setHMIAppId(d1.params.application.appID, 1)
      else
        m.setHMIAppId(d1.params.application.appID, 2)
      end
      if exp.occurences == 1 then
        local corId2 = m.getMobileSession(2):SendRPC("RegisterAppInterface", requestParams2)
        m.getMobileSession(2):ExpectResponse(corId2, { success = true, resultCode = pResultCode2ndApp })
      end
    end)
  :Times(2)

  local corId1 = m.getMobileSession(1):SendRPC("RegisterAppInterface", requestParams1)
  m.getMobileSession(1):ExpectResponse(corId1, { success = true, resultCode = pResultCode1stApp })

  m.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp", { appID = m.getHMIAppId(2) })
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, "BasicCommunication.ActivateApp", "SUCCESS", {})
    end)

  m.getMobileSession(1):ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
    { hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE" })
  :Times(2)

  m.getMobileSession(2):ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
    { hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" })
  :Times(2)

  pCheckResumptionData()
  m.wait(3000)
end

function m.sessionCreationOpenRPCservice(pAppId)
  local mobSession = actions.mobile.createSession(pAppId)
  mobSession:StartService(7)
end

function m.onInteriorVD2Apps(pModuleType, pNotifTimes1app, pNotifTimes2app, pModuleId)
  pModuleId = pModuleId or m.getModuleId(pModuleType, 1)
  m.getHMIConnection():SendNotification("RC.OnInteriorVehicleData",
    { moduleData = m.getActualModuleIVData(pModuleType, pModuleId) })
  m.getMobileSession(1):ExpectNotification("OnInteriorVehicleData")
  :Times(pNotifTimes1app)
  m.getMobileSession(2):ExpectNotification("OnInteriorVehicleData")
  :Times(pNotifTimes2app)
end

return m
