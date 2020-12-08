---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local actions = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")
local events = require("events")
local SDL = require('SDL')
local color = require("user_modules/consts").color

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 2
config.application2.registerAppInterfaceParams = config.application1.registerAppInterfaceParams

if config.defaultMobileAdapterType ~= "TCP" then
  runner.skipTest("Test is applicable only for TCP connection")
end

--[[ Shared Functions ]]
local m = {}
m.Title = runner.Title
m.Step = runner.Step
m.testSettings = runner.testSettings
m.preconditions = actions.preconditions
m.postconditions = actions.postconditions
m.allowSDL = actions.mobile.allowSDL

--[[ Common Functions ]]
function m.startWithoutMobile(pHMIParams)
  local event = events.Event()
  event.matches = function(e1, e2) return e1 == e2 end
  actions.init.SDL()
  :Do(function()
    actions.init.HMI()
      :Do(function()
        actions.init.HMI_onReady(pHMIParams)
          :Do(function()
            actions.hmi.getConnection():RaiseEvent(event, "Start event")
            end)
        end)
    end)
  return actions.hmi.getConnection():ExpectEvent(event, "Start event")
end

local function connectMobDevice(pMobConnId, pDeviceInfo, pIsSDLAllowed)
  if pIsSDLAllowed == nil then pIsSDLAllowed = true end
  utils.addNetworkInterface(pMobConnId, pDeviceInfo.host)
  actions.mobile.createConnection(pMobConnId, pDeviceInfo.host, pDeviceInfo.port)
  local mobConnectExp = actions.mobile.connect(pMobConnId)
  if pIsSDLAllowed then
    mobConnectExp:Do(function()
      actions.mobile.allowSDL(pMobConnId)
      end)
  end
end

function m.deleteMobDevice(pMobConnId)
  utils.deleteNetworkInterface(pMobConnId)
end

function m.connectMobDevices(pDevices)
  for i = 1, #pDevices do
    connectMobDevice(i, pDevices[i], pDevices[i].hasAutoConsent)
  end
end

function m.clearMobDevices(pDevices)
  for i = 1, #pDevices do
    m.deleteMobDevice(i)
  end
end

local function registerApp(pAppId, pMobConnId, hasPTU)
  if not pAppId then pAppId = 1 end
  if not pMobConnId then pMobConnId = 1 end
  local session = actions.mobile.createSession(pAppId, pMobConnId)
  session:StartService(7)
  :Do(function()
      local corId = session:SendRPC("RegisterAppInterface", actions.app.getParams(pAppId))
      actions.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = actions.app.getParams(pAppId).appName } })
      :Do(function(_, d1)
          actions.app.setHMIId(d1.params.application.appID, pAppId)
          if hasPTU then
            actions.ptu.expectStart()
          end
        end)
      session:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          session:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
        end)
    end)
end

function m.registerApp(pAppId, pMobConnId)
  registerApp(pAppId, pMobConnId, true)
end

function m.registerAppNoPTU(pAppId, pMobConnId)
  registerApp(pAppId, pMobConnId, false)
end

function m.activateRevokedApp(pAppId, pIsSdlAllowed)
  actions.mobile.getSession(pAppId):ExpectNotification("OnHMIStatus"):Times(0)
  local requestId = actions.hmi.getConnection():SendRequest("SDL.ActivateApp", { appID = actions.app.getHMIId(pAppId) })
  actions.hmi.getConnection():ExpectResponse(requestId,
    { result = { isSDLAllowed = pIsSdlAllowed, isAppRevoked = true } })
end

function m.disallowSDL(pMobConnId)
  if pMobConnId == nil then pMobConnId = 1 end
  local connection = actions.mobile.getConnection(pMobConnId)
  local hmi = actions.hmi.getConnection()
  local event = actions.run.createEvent()
  hmi:SendNotification("SDL.OnAllowSDLFunctionality", {
    allowed = false,
    source = "GUI",
    device = {
      id = utils.getDeviceMAC(connection.host, connection.port),
      name = utils.getDeviceName(connection.host, connection.port)
    }
  })
  actions.run.runAfter(function() hmi:RaiseEvent(event, "Disallow SDL event") end, 500)
  return hmi:ExpectEvent(event, "Disallow SDL event")
end

function m.consentDevice(pDeviceId)
  for _, session in pairs(actions.mobile.getApps(pDeviceId)) do
    session:ExpectNotification("OnHMIStatus"):Times(0)
  end
  actions.hmi.getConnection():ExpectRequest("BasicCommunication.ActivateApp"):Times(0)
  actions.mobile.allowSDL(pDeviceId)
end

local function policyUpdate(pPolicyTable)
  pPolicyTable.policy_table.functional_groupings["DataConsent-2"].rpcs = actions.json.null
  pPolicyTable.policy_table.app_policies[actions.app.getPolicyAppId(1)] = actions.json.null
end

function m.revokeAppViaPtu()
  actions.ptu.policyTableUpdate(policyUpdate)
end

function m.revokeAppViaPreloadedPT()
  local pt = actions.sdl.getPreloadedPT()
  policyUpdate(pt)
  actions.sdl.setPreloadedPT(pt)
end

function m.ignitionOff()
  local isOnSDLCloseSent = false
  local hmi = actions.hmi.getConnection()
  hmi:SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  hmi:ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
    hmi:SendNotification("BasicCommunication.OnExitAllApplications", { reason = "IGNITION_OFF" })
    hmi:ExpectNotification("BasicCommunication.OnSDLClose")
    :Do(function()
      isOnSDLCloseSent = true
      SDL.DeleteFile()
    end)
  end)
  actions.run.wait(3000)
  :Do(function()
    if isOnSDLCloseSent == false then utils.cprint(color.magenta, "BC.OnSDLClose was not sent") end
    for i = 1, actions.mobile.getAppsCount() do
      actions.mobile.deleteSession(i)
    end
    StopSDL()
  end)
end

return m
