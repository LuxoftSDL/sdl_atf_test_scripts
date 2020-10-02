---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")
local events = require('events')
local runner = require('user_modules/script_runner')
local hmi_values = require("user_modules/hmi_values")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 2

--[[ Shared Functions ]]
local m = {}
m.Title = runner.Title
m.Step = runner.Step
m.start = actions.start
m.preconditions = actions.preconditions
m.postconditions = actions.postconditions
m.spairs = utils.spairs

--[[ Common Variables ]]
m.characterSets = { "ASCII", "ISO_8859_1", "UTF_8" }

--[[ Common Functions ]]
local function excludeAbsentInMobApiTextFields(pTextFields)
  if type(pTextFields) == "table" then
    local textFieldsToExclude = {"timeToDestination", "turnText", "navigationText", "notificationText" }
    for _, excludeTextFieldName in ipairs(textFieldsToExclude) do
      local isFound = false
      local i = #pTextFields
      repeat
        if pTextFields[i].name == excludeTextFieldName then
          table.remove(pTextFields, i)
          isFound = true
        end
        i = i - 1
      until (isFound or i < 1)
    end
  end
end

function  m.getSystemCapability(pCharacterSetValue)
  local uiCap = m.getHMITableWithUpdCharacterSet(pCharacterSetValue).UI.GetCapabilities
  local expectedTextFields = uiCap.params.displayCapabilities.textFields
  local mobSession = actions.mobile.getSession()
  local cid = mobSession:SendRPC("GetSystemCapability", { systemCapabilityType = "DISPLAYS" })
  mobSession:ExpectResponse(cid, {
    success = true,
    resultCode = "SUCCESS",
     systemCapability = { displayCapabilities = {{ windowCapabilities = {{ textFields = expectedTextFields}} }}}
  })
end

function m.getHMITableWithUpdCharacterSet(pCharacterSetValue)
  local hmiCaps = hmi_values.getDefaultHMITable()
  excludeAbsentInMobApiTextFields(hmiCaps.UI.GetCapabilities.params.displayCapabilities.textFields)
  for key in pairs(hmiCaps.UI.GetCapabilities.params.displayCapabilities.textFields) do
    hmiCaps.UI.GetCapabilities.params.displayCapabilities.textFields[key].characterSet = pCharacterSetValue
  end
  return hmiCaps
end

function m.registerApp(pCharacterSetValue)
  local uiCap = m.getHMITableWithUpdCharacterSet(pCharacterSetValue).UI.GetCapabilities
  local expectedTextFields = uiCap.params.displayCapabilities.textFields
  local appId = 1
  local session = actions.mobile.createSession(appId)
  session:StartService(7)
  :Do(function()
      local corId = session:SendRPC("RegisterAppInterface", actions.app.getParams(appId))
      actions.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = actions.app.getParams(appId).appName }})
      session:ExpectResponse(corId, {
        success = true,
        resultCode = "SUCCESS",
        displayCapabilities = { textFields = expectedTextFields }
      })
      :Do(function()
          session:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
        end)
    end)
end

function m.ignitionOff()
  local hmiConnection = actions.hmi.getConnection()
  local mobileConnection = actions.mobile.getConnection()
  config.ExitOnCrash = false
  local timeout = 5000
  local function removeSessions()
    for i = 1, actions.mobile.getAppsCount() do
      actions.mobile.deleteSession(i)
    end
  end
  local event = events.Event()
  event.matches = function(event1, event2) return event1 == event2 end
  mobileConnection:ExpectEvent(event, "SDL shutdown")
  :Do(function()
    removeSessions()
    StopSDL()
    config.ExitOnCrash = true
  end)
  hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  hmiConnection:ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
    hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",{ reason = "IGNITION_OFF" })
    for i = 1, actions.mobile.getAppsCount() do
      actions.mobile.getSession(i):ExpectNotification("OnAppInterfaceUnregistered", { reason = "IGNITION_OFF" })
    end
  end)
  hmiConnection:ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
  :Times(actions.mobile.getAppsCount())
  local isSDLShutDownSuccessfully = false
  hmiConnection:ExpectNotification("BasicCommunication.OnSDLClose")
  :Do(function()
    utils.cprint(35, "SDL was shutdown successfully")
    isSDLShutDownSuccessfully = true
    mobileConnection:RaiseEvent(event, event)
  end)
  :Timeout(timeout)
  local function forceStopSDL()
    if isSDLShutDownSuccessfully == false then
      utils.cprint(35, "SDL was shutdown forcibly")
      mobileConnection:RaiseEvent(event, event)
    end
  end
  actions.run.runAfter(forceStopSDL, timeout + 500)
end

function m.onSystemCapabilityUpdated(pCharacterSetValue)
  local uiCap = m.getHMITableWithUpdCharacterSet(pCharacterSetValue).UI.GetCapabilities
  local textFieldsValue = uiCap.params.displayCapabilities.textFields
  local onSystemCapabilityUpdatedParams = {
    systemCapability = {
      systemCapabilityType = "DISPLAYS",
      displayCapabilities = {
        {
          displayName = "displayName",
          windowCapabilities = {
            {
              menuLayoutsAvailable = { "LIST", "TILES" },
              textFields = textFieldsValue
            }
          }
        }
      }
    }
  }

  actions.hmi.getConnection():SendNotification("BasicCommunication.OnSystemCapabilityUpdated",
    onSystemCapabilityUpdatedParams)
  actions.mobile.getSession():ExpectNotification("OnSystemCapabilityUpdated", onSystemCapabilityUpdatedParams)
end

function m.getHMIParamsWithOutRequests()
  local params = m.getHMITableWithUpdCharacterSet()
  params.RC.GetCapabilities.occurrence = 0
  params.UI.GetSupportedLanguages.occurrence = 0
  params.UI.GetCapabilities.occurrence = 0
  params.VR.GetSupportedLanguages.occurrence = 0
  params.VR.GetCapabilities.occurrence = 0
  params.TTS.GetSupportedLanguages.occurrence = 0
  params.TTS.GetCapabilities.occurrence = 0
  params.Buttons.GetCapabilities.occurrence = 0
  params.VehicleInfo.GetVehicleType.occurrence = 0
  params.UI.GetLanguage.occurrence = 0
  params.VR.GetLanguage.occurrence = 0
  params.TTS.GetLanguage.occurrence = 0
  return params
end

return m
