---------------------------------------------------------------------------------------------------
-- common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.application1.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }
config.application2.registerAppInterfaceParams.appHMIType = { "MEDIA" }
config.application1.registerAppInterfaceParams.isMediaApplication = false
config.application2.registerAppInterfaceParams.isMediaApplication = true

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local utils = require('user_modules/utils')
local json = require("modules/json")
local atf_logger = require("atf_logger")
local SDL = require('SDL')
local color = require("user_modules/consts").color

--[[ Override expectation's default timeout ]]
local expectations = require('expectations')
local expOrig = expectations.Expectation
expectations.Expectation = function(...)
  local f = expOrig(...)
  f.timeout = 12000
  return f
end

--[[ Common Variables ]]
local m = actions
m.cloneTable = utils.cloneTable
m.wait = utils.wait
m.tableToString = utils.tableToString
m.connectMobile = actions.mobile.connect

m.hashId = {}
m.resumptionData = {
  [1] = {},
  [2] = {}
}

m.rpcs = {
  addCommand = { "UI", "VR" },
  addSubMenu = { "UI" },
  createIntrerationChoiceSet = { "VR" },
  setGlobalProperties = { "UI", "TTS" },
  subscribeVehicleData = { "VehicleInfo" },
  subscribeWayPoints = { "Navigation" },
  createWindow = { "UI" }
}

--[[ Local Functions ]]

local function getOnSCUParams(pWinArray)
  local params = {
    systemCapability = {
      systemCapabilityType = "DISPLAYS",
      displayCapabilities = {
        {
          displayName = "displayName",
          windowTypeSupported = {
            {
              type = "MAIN",
              maximumNumberOfWindows = 1
            },
            {
              type = "WIDGET",
              maximumNumberOfWindows = 1
            }
          },
          windowCapabilities = { }
        }
      }
    }
  }
  for _, winId in pairs(pWinArray) do
    local winCap = {
      windowID = winId,
      templatesAvailable = { "Template_" .. winId }
    }
    table.insert(params.systemCapability.displayCapabilities[1].windowCapabilities, winCap)
  end
  return params
end

--[[ Common Functions ]]

--[[ @waitUntilResumptionDataIsStored: wait some time until SDL saves resumption data
--! @parameters: none
--! @return: none
--]]
function m.waitUntilResumptionDataIsStored()
  utils.cprint(color.magenta, "Wait ...")
  local timeoutToSafe = SDL.INI.get("AppSavePersistentDataTimeout")
  local fileName = SDL.AppInfo.file()
  local function isFileExist()
    local f = io.open(fileName, "r")
    if f ~= nil then
      io.close(f)
      m.wait(timeoutToSafe + 1000)
      return true
    else
      return false
    end
  end
  while not isFileExist() do
    os.execute("sleep 1")
  end
end

--[[ @checkResumptionData: checks resumption data and answer with error to defined RPC
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pErrorResponseRpc - RPC for response with errorCode
--! pErrorResponseInterface - interface of RPC for response with errorCode
--! @return: none
--]]
function m.checkResumptionData(pAppId, pErrorResponseRpc, pErrorResponseInterface)
  for rpc in pairs(m.resumptionData[pAppId]) do
    if pErrorResponseRpc == rpc then
      m[rpc .. "Resumption"](pAppId, pErrorResponseInterface)
    else
      m[rpc .. "Resumption"](pAppId)
    end
  end
end

--[[ @expOnHMIStatus: check OnHMIStatus notification
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pExpLevel - expected HMI level ('FULL' or 'LIMITED')
--! pErrorResponseRpc - RPC for response with errorCode
--! pTimeout - timeout to wait
--! @return: none
--]]
local function expOnHMIStatus(pAppId, pExpLevel, pErrorResponseRpc, pTimeout)
  if not pTimeout then pTimeout = 10000 end
  local exp = {
    { hmiLevel = "NONE", windowID = 0 },
    { hmiLevel = "NONE", windowID = 2 },
    { hmiLevel = pExpLevel, windowID = 0 }
  }
  if m.resumptionData[pAppId].createWindow == nil or (pErrorResponseRpc ~= nil and pAppId == 1) then
    table.remove(exp, 2)
  end
  m.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",table.unpack(exp))
  :Times(#exp)
  :Timeout(pTimeout)
end

--[[ @resumptionFullHMILevel: checks resumption to full HMI level
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pTimeout - timeout to wait
--! @return: none
--]]
function m.resumptionFullHMILevel(pAppId, pErrorResponseRpc, pTimeout)
  if not pTimeout then pTimeout = 10000 end
  expOnHMIStatus(pAppId, "FULL", pErrorResponseRpc, pTimeout)
  m.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp", { appID = m.getHMIAppId(pAppId) })
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, "BasicCommunication.ActivateApp", "SUCCESS", {})
    end)
  :Timeout(pTimeout)
end

--[[ @getRpcName: construct RPC name for HMI messages
--! @parameters:
--! pRpcName - name of RPC
--! pInterfaceName - name of RPC interface
--! @return: RPC with interface
--]]
function m.getRpcName(pRpcName, pInterfaceName)
  local rpcName = pRpcName:gsub("^%l", string.upper)
  return pInterfaceName .. "." .. rpcName
end

m.removeData = {
  DeleteUICommand = function(pAppId)
    local deleteCommandRequestParams = { }
    deleteCommandRequestParams.cmdID = m.resumptionData[pAppId].addCommand.UI.cmdID
    deleteCommandRequestParams.appID = m.resumptionData[pAppId].addCommand.UI.appID
    m.getHMIConnection():ExpectRequest("UI.DeleteCommand", deleteCommandRequestParams)
    :Do(function(_,deleteData)
        m.sendResponse(deleteData)
      end)
  end,
  DeleteVRCommand = function(pAppId, pRequestType, pTimes)
    if not pTimes then pTimes = 2 end
    local deleteCommandRequestParams
    if pTimes == 1 then
      if pRequestType == "Choice" then
        deleteCommandRequestParams = m.cloneTable(m.resumptionData[pAppId].createIntrerationChoiceSet.VR)
      else
        deleteCommandRequestParams = m.cloneTable(m.resumptionData[pAppId].addCommand.VR)
      end
      deleteCommandRequestParams.vrCommands = nil
    else
      deleteCommandRequestParams = {}
      deleteCommandRequestParams[1] = m.cloneTable(m.resumptionData[pAppId].addCommand.VR)
      deleteCommandRequestParams[1].vrCommands = nil
      deleteCommandRequestParams[2] = m.cloneTable(m.resumptionData[pAppId].createIntrerationChoiceSet.VR)
      deleteCommandRequestParams[2].vrCommands = nil
    end
    deleteCommandRequestParams.vrCommands = nil
      m.getHMIConnection():ExpectRequest("VR.DeleteCommand", deleteCommandRequestParams[1], deleteCommandRequestParams[2])
      :Do(function(_,deleteData)
          m.sendResponse(deleteData)
        end)
      :Times(pTimes)
  end,
  DeleteSubMenu = function(pAppId)
    local deleteSubMenuRequestParams = {}
    deleteSubMenuRequestParams.menuID = m.resumptionData[pAppId].addSubMenu.UI.menuID
    deleteSubMenuRequestParams.appID = m.resumptionData[pAppId].addSubMenu.UI.appID
    m.getHMIConnection():ExpectRequest("UI.DeleteSubMenu", deleteSubMenuRequestParams)
    :Do(function(_,deleteData)
        m.sendResponse(deleteData)
      end)
  end,
  UnsubscribeVehicleData = function(pAppId)
    m.getHMIConnection():ExpectRequest("VehicleInfo.UnsubscribeVehicleData", m.resumptionData[pAppId].subscribeVehicleData.VehicleInfo)
    :Do(function(_,deleteData)
        m.sendResponse(deleteData)
      end)
  end,
  UnsubscribeWayPoints = function(pAppId, pTimes)
    if not pTimes then pTimes = 1 end
    m.getHMIConnection():ExpectRequest("Navigation.UnsubscribeWayPoints", m.resumptionData[pAppId].subscribeWayPoints.Navigation)
    :Do(function(_,deleteData)
        m.sendResponse(deleteData)
      end)
    :Times(pTimes)
  end,
  DeleteWindow = function(pAppId)
    local params = {
      appID = m.getHMIAppId(pAppId),
      windowID = m.resumptionData[pAppId].createWindow.UI.windowID
    }
    m.getHMIConnection():ExpectRequest("UI.DeleteWindow", params)
    :Do(function(_,deleteData)
        m.sendResponse(deleteData)
      end)
  end
}

--[[ @getGlobalPropertiesResetData: construct data for reset SetGlobalProperties
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pInterface - name of RPC interface for reseting
--! @return: RPC with interface
--]]
local function getGlobalPropertiesResetData(pAppId, pInterface)
  local resetData = {}
  resetData.appID = m.getHMIAppId(pAppId)
  if pInterface == "TTS" then
    resetData.helpPrompt = { }
    resetData.timeoutPrompt = { }
    local ttsDelimiter = SDL.INI.get("TTSDelimiter")
    local helpPromptString = SDL.INI.get("HelpPromt")
    local helpPromptList = m.splitString(helpPromptString, ttsDelimiter);

    for key,value in pairs(helpPromptList) do
      local data = {
        type = "TEXT",
        text = value .. ttsDelimiter
      }
      resetData.timeoutPrompt[key] = data
      resetData.helpPrompt[key] = data
    end
  else
    resetData.menuTitle = ""
    resetData.vrHelp = { [1] = { position = 1, text = m.getConfigAppParams(pAppId).appName }}
    resetData.vrHelpTitle = SDL.INI.get("HelpTitle")
  end
  return resetData
end

m.rpcsRevert = {
  addCommand = {
    rpc = "DeleteCommand",
    iface = {
      UI = function(pAppId, pTimes)
        if not pTimes then pTimes = 1 end
        m.getHMIConnection():ExpectRequest("UI.AddCommand",m.resumptionData[pAppId].addCommand.UI)
        :Do(function(_, data)
            m.sendResponse(data)
            m.removeData.DeleteUICommand(pAppId)
          end)
        :Times(pTimes)
      end,
      VR = function(pAppId, pTimes)
        if not pTimes then pTimes = 2 end
        m.getHMIConnection():ExpectRequest("VR.AddCommand")
        :Do(function(exp, data)
            m.sendResponse(data)
            if pTimes == 2 and exp.occurences == 1 then
              m.removeData.DeleteVRCommand(pAppId, nil, 2)
            elseif pTimes == 1 then
              m.removeData.DeleteVRCommand(pAppId, data.params.type)
            end
          end)
        :ValidIf(function(_, data)
            if data.params.type == "Choice" then
              if utils.isTableEqual(data.params, m.resumptionData[pAppId].createIntrerationChoiceSet.VR) == false then
                return false, "Params in VR.AddCommand with type = Choice are not match to expected result.\n" ..
                "Actual result:" .. m.tableToString(data.params) .. "\n" ..
                "Expected result:" .. m.tableToString(m.resumptionData[pAppId].createIntrerationChoiceSet.VR) .."\n"
              end
            else
              if utils.isTableEqual(data.params, m.resumptionData[pAppId].addCommand.VR) == false then
                return false, "Params in VR.AddCommand with type = Command are not match to expected result.\n" ..
                "Actual result:" .. m.tableToString(data.params) .. "\n" ..
                "Expected result:" .. m.tableToString(m.resumptionData[pAppId].addCommand.VR) .."\n"
              end
            end
            return true
          end)
        :Times(pTimes)
      end
    }
  },
  addSubMenu = {
    rpc = "DeleteSubMenu",
    iface = {
      UI = function(pAppId, pTimes)
        if not pTimes then pTimes = 1 end
        m.getHMIConnection():ExpectRequest("UI.AddSubMenu",m.resumptionData[pAppId].addSubMenu.UI)
        :Do(function(_, data)
            m.sendResponse(data)
            m.removeData.DeleteSubMenu(pAppId)
          end)
        :Times(pTimes)
      end
    }
  },
  createIntrerationChoiceSet = {
    rpc = "DeleteCommand",
    iface = {
      VR = function() end
    }
  },
  setGlobalProperties = {
    rpc = "SetGlobalProperties",
    iface = {
      TTS = function(pAppId, pTimes)
        if not pTimes then pTimes = 2 end
        m.getHMIConnection():ExpectRequest("TTS.SetGlobalProperties")
        :Do(function(_, data)
            m.sendResponse(data)
          end)
        :ValidIf(function(exp, data)
            if exp.occurences == 1 then
              if utils.isTableEqual(data.params, m.resumptionData[pAppId].setGlobalProperties.TTS) == true then
                return true
              else
                return false, "Params in TTS.SetGlobalProperties are not match to expected result.\n" ..
                "Actual result:" .. m.tableToString(data.params) .. "\n" ..
                "Expected result:" .. m.tableToString(m.resumptionData[pAppId].setGlobalProperties.TTS) .."\n"
              end
            else
              local resetData = getGlobalPropertiesResetData(pAppId, "TTS")
              if utils.isTableEqual(data.params, resetData) == true then
                return true
              else
                return false, "Params in TTS.SetGlobalProperties are not match to expected result.\n" ..
                "Actual result:" .. m.tableToString(data.params) .. "\n" ..
                "Expected result:" .. m.tableToString(resetData) .."\n"
              end
            end
          end)
        :Times(pTimes)
      end,
      UI = function(pAppId, pTimes)
        if not pTimes then pTimes = 2 end
        m.getHMIConnection():ExpectRequest("UI.SetGlobalProperties")
        :Do(function(_, data)
            m.sendResponse(data)
          end)
        :ValidIf(function(exp, data)
            if exp.occurences == 1 then
              if utils.isTableEqual(data.params, m.resumptionData[pAppId].setGlobalProperties.UI) == true then
                return true
              else
                return false, "Params in UI.SetGlobalProperties are not match to expected result.\n" ..
                "Actual result:" .. m.tableToString(data.params) .. "\n" ..
                "Expected result:" .. m.tableToString(m.resumptionData[pAppId].setGlobalProperties.UI) .."\n"
              end
            else
              local resetData = getGlobalPropertiesResetData(pAppId, "UI")
              if utils.isTableEqual(data.params, resetData) == true then
                return true
              else
                return false, "Params in UI.SetGlobalProperties are not match to expected result.\n" ..
                "Actual result:" .. m.tableToString(data.params) .. "\n" ..
                "Expected result:" .. m.tableToString(resetData) .."\n"
              end
            end
          end)
        :Times(pTimes)
      end
    }
  },
  subscribeVehicleData = {
    rpc = "UnsubscribeVehicleData",
    iface = {
      VehicleInfo = function(pAppId,pTimes)
        if not pTimes then pTimes = 1 end
        m.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData",m.resumptionData[pAppId].subscribeVehicleData.VehicleInfo)
        :Do(function(_, data)
            m.sendResponse(data)
            m.removeData.UnsubscribeVehicleData(pAppId)
          end)
        :Times(pTimes)
      end
    }
  },
  subscribeWayPoints = {
    rpc = "UnsubscribeWayPoints",
    iface = {
      Navigation = function(pAppId, pTimes)
        if not pTimes then pTimes = 1 end
        m.getHMIConnection():ExpectRequest("Navigation.SubscribeWayPoints",m.resumptionData[pAppId].subscribeWayPoints.Navigation)
        :Do(function(_, data)
            m.sendResponse(data)
            m.removeData.UnsubscribeWayPoints(pAppId)
          end)
        :Times(pTimes)
      end
    }
  },
  createWindow = {
    rpc = "DeleteWindow",
    iface = {
      UI = function(pAppId, pTimes)
        if not pTimes then pTimes = 1 end
        m.getHMIConnection():ExpectRequest("UI.CreateWindow",m.resumptionData[pAppId].createWindow.UI)
        :Do(function(_, data)
            m.sendResponse(data)
            m.sendOnSCU(2, pAppId)
            m.removeData.DeleteWindow(pAppId)
          end)
        :Times(pTimes)
      end
    }
  }
}

--[[ @checkResumptionDataWithErrorResponse: check resumption data for with error response to defined rpc and
--! checking reverting already added data
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pErrorResponseRpc - RPC name for error response
--! pErrorResponseInterface - interface of RPC for error response
--! @return: none
]]
function m.checkResumptionDataWithErrorResponse(pAppId, pErrorResponseRpc, pErrorResponseInterface)
  local rpcsRevertLocal = m.cloneTable(m.rpcsRevert)
  if pErrorResponseRpc == "addCommand" and pErrorResponseInterface == "VR" then
    rpcsRevertLocal.addCommand.iface.VR = nil
    m.getHMIConnection():ExpectRequest("VR.AddCommand")
    :Do(function(_, data)
        if data.params.type == "Command" then
          m.errorResponse(data)
        else
          m.sendResponse(data)
          m.removeData.DeleteVRCommand(pAppId, data.params.type, 1)
        end
      end)
    :Times(2)
  elseif pErrorResponseRpc == "createIntrerationChoiceSet" then
    rpcsRevertLocal.addCommand.iface.VR = nil
    m.getHMIConnection():ExpectRequest("VR.AddCommand")
    :Do(function(_, data)
        if data.params.type == "Choice" then
          m.errorResponse(data)
        else
          m.sendResponse(data)
          m.removeData.DeleteVRCommand(pAppId, data.params.type, 1)
        end
      end)
    :Times(2)
  else
    local errorResponseRpc = m.getRpcName(pErrorResponseRpc, pErrorResponseInterface)
    local revertRpc = rpcsRevertLocal[pErrorResponseRpc].rpc
    local notExpRevertRpc = m.getRpcName(revertRpc, pErrorResponseInterface)
    rpcsRevertLocal[pErrorResponseRpc].iface[pErrorResponseInterface] = nil
    if pErrorResponseRpc ~= "setGlobalProperties" then
      m.getHMIConnection():ExpectRequest(notExpRevertRpc)
      :Times(0)
    end
    m.getHMIConnection():ExpectRequest(errorResponseRpc)
    :Do(function(_, data)
        m.errorResponse(data)
      end)
  end
  for rpc, data in pairs(rpcsRevertLocal) do
    if m.resumptionData[pAppId][rpc] then
      for interface in pairs(data.iface) do
        rpcsRevertLocal[rpc].iface[interface](pAppId)
      end
    end
  end

  local isCustomButtonSubscribed = false
  local isOkButtonSubscribed = false
  local isOkButtonUnsubscribed = false
  m.getHMIConnection():ExpectNotification("Buttons.OnButtonSubscription")
  :ValidIf(function(_, data)
      local params = data.params
      if params.name == "CUSTOM_BUTTON" and params.isSubscribed == true and isCustomButtonSubscribed == false then
        isCustomButtonSubscribed = true
      elseif params.name == "OK" and params.isSubscribed == true and isOkButtonSubscribed == false then
        isOkButtonSubscribed = true
      elseif params.name == "OK" and params.isSubscribed == false and isOkButtonUnsubscribed == false then
        isOkButtonUnsubscribed = true
      else
        return false, "Came unexpected Buttons.OnButtonSubscription notification"
      end
      return true
    end)
  :Times(3)
end

--[[ @reRegisterApp: re-register application with RESUME_FAILED resultCode
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pCheckResumptionData - verification function for resumption data
--! pCheckResumptionHMILevel - verification function for resumption HMI level
--! pErrorResponseRpc - RPC name for error response
--! pErrorResponseInterface - interface of RPC for error response
--! pRAIResponseExp - time for expectation of RAI response
--! @return: none
--]]
function m.reRegisterApp(pAppId, pCheckResumptionData, pCheckResumptionHMILevel, pErrorResponseRpc, pErrorResponseInterface, pTimeout)
  if not pAppId then pAppId = 1 end
  if not pTimeout then pTimeout = 10000 end
  local mobSession = m.getMobileSession(pAppId)
  mobSession:StartService(7)
  :Do(function()
      local params = m.cloneTable(m.getConfigAppParams(pAppId))
      params.hashID = m.hashId[pAppId]
      local corId = mobSession:SendRPC("RegisterAppInterface", params)
      m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered", {
          application = { appName = m.getConfigAppParams(pAppId).appName }
        })
      :Do(function()
          m.sendOnSCU(0, pAppId)
        end)
      mobSession:ExpectResponse(corId, { success = true, resultCode = "RESUME_FAILED" })
      :Do(function()
          mobSession:ExpectNotification("OnPermissionsChange")
          mobSession:ExpectNotification("OnSystemCapabilityUpdated")
        end)
      :Timeout(pTimeout)
    end)
  pCheckResumptionData(pAppId, pErrorResponseRpc, pErrorResponseInterface)
  pCheckResumptionHMILevel(pAppId, pErrorResponseRpc, pTimeout)
end

--[[ @reRegisterAppSuccess: re-register application with SUCCESS resultCode
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pCheckResumptionData - verification function for resumption data
--! pCheckResumptionHMILevel - verification function for resumption HMI level
--! @return: none
--]]
function m.reRegisterAppSuccess(pAppId, pCheckResumptionData, pCheckResumptionHMILevel)
  if not pAppId then pAppId = 1 end
  local mobSession = m.getMobileSession(pAppId)
  mobSession:StartService(7)
  :Do(function()
      local params = m.cloneTable(m.getConfigAppParams(pAppId))
      params.hashID = m.hashId[pAppId]
      local corId = mobSession:SendRPC("RegisterAppInterface", params)
      m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered", {
          application = { appName = m.getConfigAppParams(pAppId).appName }
        })
      :Do(function()
          m.sendOnSCU(0, pAppId)
        end)
      mobSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          mobSession:ExpectNotification("OnPermissionsChange")
          mobSession:ExpectNotification("OnSystemCapabilityUpdated")
        end)
    end)
  pCheckResumptionData(pAppId)
  pCheckResumptionHMILevel(pAppId)
end

--[[ @sendResponse: sending success and error resultCode to defined RPCs
--! @parameters:
--! pData - data from received request
--! pErrorRespInterface - interface of RPC for error response
--! pCurrentInterface - current interface of RPC
--! @return: none
--]]
function m.sendResponse(pData, pErrorRespInterface, pCurrentInterface)
  if pErrorRespInterface ~= nil and pErrorRespInterface == pCurrentInterface then
    m.getHMIConnection():SendError(pData.id, pData.method, "GENERIC_ERROR", "info message")
  else
    m.getHMIConnection():SendResponse(pData.id, pData.method, "SUCCESS", {})
  end
end

--[[ @addCommand: adding command
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.addCommand(pAppId)
  if not pAppId then pAppId = 1 end
  local params = {
    cmdID = pAppId,
    vrCommands = { "vr" .. m.getConfigAppParams(pAppId).appName },
    menuParams = { menuName = "command" .. m.getConfigAppParams(pAppId).appName}

  }
  m.resumptionData[pAppId]["addCommand"] = {}
  local cid = m.getMobileSession(pAppId):SendRPC("AddCommand", params)
  m.getHMIConnection():ExpectRequest("VR.AddCommand")
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      m.resumptionData[pAppId].addCommand.VR = data.params
    end)
  m.getHMIConnection():ExpectRequest("UI.AddCommand")
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      m.resumptionData[pAppId].addCommand.UI = data.params
    end)
  m.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_, data)
      m.hashId[pAppId] = data.payload.hashID
    end)
  -- wait for SetGlobalproperties requests from SDL during AddCommand to not affect another case with SetGP
  m.wait(300)
end

--[[ @addSubMenu: adding subMenu
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.addSubMenu(pAppId)
  if not pAppId then pAppId = 1 end
  local params = {
    menuID = pAppId,
    position = 500,
    menuName = "SubMenu" .. m.getConfigAppParams(pAppId).appName
  }
  local cid = m.getMobileSession(pAppId):SendRPC("AddSubMenu", params)
  m.getHMIConnection():ExpectRequest("UI.AddSubMenu")
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      m.resumptionData[pAppId].addSubMenu = { UI = data.params }
    end)
  m.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_, data)
      m.hashId[pAppId] = data.payload.hashID
    end)
end

--[[ @createIntrerationChoiceSet: adding createIntrerationChoiceSet
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.createIntrerationChoiceSet(pAppId)
  if not pAppId then pAppId = 1 end
  local choice = {
    choiceID = pAppId,
    menuName = "Choice" .. m.getConfigAppParams(pAppId).appName,
    vrCommands = { "VrChoice" ..m.getConfigAppParams(pAppId).appName }
  }
  local cid = m.getMobileSession(pAppId):SendRPC("CreateInteractionChoiceSet", {
      interactionChoiceSetID = pAppId,
      choiceSet = { choice }
    })
  m.getHMIConnection():ExpectRequest("VR.AddCommand")
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      m.resumptionData[pAppId].createIntrerationChoiceSet = { VR = data.params }
    end)
  m.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_, data)
      m.hashId[pAppId] = data.payload.hashID
    end)
end

--[[ @setGlobalProperties: adding setGlobalProperties
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.setGlobalProperties(pAppId)
  if not pAppId then pAppId = 1 end
  local params = {
    helpPrompt = {
      {
        text = "Help prompt" .. pAppId,
        type = "TEXT"
      }
    },
    timeoutPrompt = {
      {
        text = "Timeout prompt" .. pAppId,
        type = "TEXT"
      }
    },
    vrHelpTitle = "VR help title" .. pAppId,
    vrHelp = {
      {
        position = 1,
        text = "VR help item" .. pAppId
      }
    },
    menuTitle = "Menu Title" .. pAppId,
  }
  local cid = m.getMobileSession(pAppId):SendRPC("SetGlobalProperties", params)
  m.resumptionData[pAppId].setGlobalProperties = {}
  m.getHMIConnection():ExpectRequest("UI.SetGlobalProperties")
  :Do(function(_,data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      m.resumptionData[pAppId].setGlobalProperties.UI = data.params
    end)

  m.getHMIConnection():ExpectRequest("TTS.SetGlobalProperties")
  :Do(function(_,data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      m.resumptionData[pAppId].setGlobalProperties.TTS = data.params
    end)

  m.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_, data)
      m.hashId[pAppId] = data.payload.hashID
    end)
end

--[[ @subscribeVehicleData: adding subscribeVehicleData
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pParams - parameters for SubscribeVehicleData mobile request
--! pHMIrequest - number of expected VI.SubscribeVehicleData HMI requests
--! @return: none
--]]
function m.subscribeVehicleData(pAppId, pParams, pHMIrequest)
  if not pAppId then pAppId = 1 end
  if not pParams then
    pParams = {
      requestParams = { gps = true },
      responseParams = { gps = { resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS" } }
    }
  end
  if not pHMIrequest then pHMIrequest = 1 end
  local cid = m.getMobileSession(pAppId):SendRPC("SubscribeVehicleData", pParams.requestParams)
  m.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData")
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", pParams.responseParams)
      m.resumptionData[pAppId].subscribeVehicleData = { VehicleInfo = data.params }
    end)
  :Times(pHMIrequest)
  local MobResp = pParams.responseParams
  MobResp.success = true
  MobResp.resultCode = "SUCCESS"
  m.getMobileSession(pAppId):ExpectResponse(cid, MobResp)
  m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_, data)
      m.hashId[pAppId] = data.payload.hashID
    end)
end

--[[ @subscribeWayPoints: adding subscribeWayPoints
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pHMIrequest - number of expected Navigation.SubscribeWayPoints HMI requests
--! @return: none
--]]
function m.subscribeWayPoints(pAppId, pHMIrequest)
  if not pAppId then pAppId = 1 end
  if not pHMIrequest then pHMIrequest = 1 end
  local cid = m.getMobileSession(pAppId):SendRPC("SubscribeWayPoints", {})
  m.getHMIConnection():ExpectRequest("Navigation.SubscribeWayPoints")
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      m.resumptionData[pAppId].subscribeWayPoints = { Navigation = data.params }
    end)
  :Times(pHMIrequest)
  m.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_, data)
      m.hashId[pAppId] = data.payload.hashID
    end)
end

--[[ @buttonSubscription: adding buttonSubscription
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.buttonSubscription(pAppId)
  if not pAppId then pAppId = 1 end
  local cid = m.getMobileSession(pAppId):SendRPC("SubscribeButton", { buttonName = "OK" })
  m.getHMIConnection():ExpectNotification("Buttons.OnButtonSubscription")
  m.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_, data)
      m.hashId[pAppId] = data.payload.hashID
    end)
end

--[[ @addCommandResumption: check resumption of addCommand data
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pErrorResponseInterface - interface of RPC for error response
--! @return: none
--]]
function m.addCommandResumption(pAppId, pErrorResponseInterface)
  if pErrorResponseInterface == "VR" then
    m.removeData.DeleteUICommand(pAppId)
  elseif pErrorResponseInterface == "UI" then
    m.removeData.DeleteVRCommand(pAppId, "Command", 1)
  end
  m.getHMIConnection():ExpectRequest("VR.AddCommand", m.resumptionData[pAppId].addCommand.VR)
  :Do(function(_, data)
      m.sendResponse(data, pErrorResponseInterface, "VR")
    end)
  m.getHMIConnection():ExpectRequest("UI.AddCommand",m.resumptionData[pAppId].addCommand.UI)
  :Do(function(_, data)
      m.sendResponse(data, pErrorResponseInterface, "UI")
    end)
end

--[[ @addSubMenuResumption: check resumption of subMenu data
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pErrorResponseInterface - interface of RPC for error response
--! @return: none
--]]
function m.addSubMenuResumption(pAppId, pErrorResponseInterface)
  m.getHMIConnection():ExpectRequest("UI.AddSubMenu",m.resumptionData[pAppId].addSubMenu.UI)
  :Do(function(_, data)
      m.sendResponse(data, pErrorResponseInterface, "UI")
    end)
end

--[[ @createIntrerationChoiceSetResumption: check resumption of choiceSet data
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pErrorResponseInterface - interface of RPC for error response
--! @return: none
--]]
function m.createIntrerationChoiceSetResumption(pAppId, pErrorResponseInterface)
  m.getHMIConnection():ExpectRequest("VR.AddCommand", m.resumptionData[pAppId].createIntrerationChoiceSet.VR)
  :Do(function(_, data)
      m.sendResponse(data, pErrorResponseInterface, "VR")
    end)
end

--[[ @setGlobalPropertiesResumption: check resumption of globalProperties data
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pErrorResponseInterface - interface of RPC for error response
--! @return: none
--]]
function m.setGlobalPropertiesResumption(pAppId, pErrorResponseInterface)
  local timesTTS = 1
  local timesUI  = 1
  local restoreData = {}
  if pErrorResponseInterface == "TTS" then
    timesUI  = 2
    restoreData = getGlobalPropertiesResetData(pAppId, "UI")
  elseif pErrorResponseInterface == "UI" then
    timesTTS = 2
    restoreData = getGlobalPropertiesResetData(pAppId, "TTS")
  end
  m.getHMIConnection():ExpectRequest("UI.SetGlobalProperties",
    m.resumptionData[pAppId].setGlobalProperties.UI,
    restoreData)
  :Do(function(_, data)
      m.sendResponse(data, pErrorResponseInterface, "UI")
    end)
  :Times(timesUI)
  m.getHMIConnection():ExpectRequest("TTS.SetGlobalProperties",
    m.resumptionData[pAppId].setGlobalProperties.TTS,
    restoreData)
  :Do(function(_, data)
      m.sendResponse(data, pErrorResponseInterface, "TTS")
    end)
  :Times(timesTTS)
end

--[[ @subscribeVehicleDataResumption: check resumption of subscribeVehicleDat data
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pErrorResponseInterface - interface of RPC for error response
--! @return: none
--]]
function m.subscribeVehicleDataResumption(pAppId, pErrorResponseInterface)
  m.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData", m.resumptionData[pAppId].subscribeVehicleData.VehicleInfo)
  :Do(function(_, data)
      m.sendResponse(data, pErrorResponseInterface, "VehicleInfo")
    end)
end

--[[ @subscribeWayPointsResumption: check resumption of subscribeWayPoints data
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pErrorResponseInterface - interface of RPC for error response
--! @return: none
--]]
function m.subscribeWayPointsResumption(pAppId, pErrorResponseInterface)
  m.getHMIConnection():ExpectRequest("Navigation.SubscribeWayPoints", m.resumptionData[pAppId].subscribeWayPoints.Navigation)
  :Do(function(_, data)
      m.sendResponse(data, pErrorResponseInterface, "Navigation")
    end)
end

--[[ @createWindowResumption: check resumption of createWindow data
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pErrorResponseInterface - interface of RPC for error response
--! @return: none
--]]
function m.createWindowResumption(pAppId, pErrorResponseInterface)
  m.getHMIConnection():ExpectRequest("UI.CreateWindow",m.resumptionData[pAppId].createWindow.UI)
  :Do(function(_, data)
      m.sendResponse(data, pErrorResponseInterface, "UI")
      if not pErrorResponseInterface then
        m.sendOnSCU(2)
      end
    end)
end

--[[ @unregisterAppInterface: unregister app
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.unregisterAppInterface(pAppId)
  if not pAppId then pAppId = 1 end
  local cid = m.getMobileSession(pAppId):SendRPC("UnregisterAppInterface",{})
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
  m.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
  :Do(function()
      actions.mobile.closeSession(pAppId)
      m.resumptionData[pAppId] = {}
    end)
end

--[[ @unexpectedDisconnect: Unexpected disconnect sequence
--! @parameters:
--! @return: none
--]]
function m.unexpectedDisconnect()
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = true })
  :Times(actions.mobile.getAppsCount())
  actions.mobile.disconnect()
  utils.wait(1000)
end

local preconditions_Orig = actions.preconditions
--[[ @preconditions: delete logs, backup preloaded file, update preloaded
--! @parameters: none
--! @return: none
--]]
function m.preconditions()
  preconditions_Orig()
  m.updatePreloadedPT()
end

--[[ @updatePreloadedPT: update preloaded file with permissions for additional RPCs
--! @parameters: none
--! @return: none
--]]
function m.updatePreloadedPT()
  local pt = actions.sdl.getPreloadedPT()
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  local additionalRPCs = {
    "SubscribeVehicleData", "UnsubscribeVehicleData", "SubscribeWayPoints", "UnsubscribeWayPoints",
    "OnVehicleData", "OnWayPointChange", "CreateWindow", "GetAppServiceData", "OnAppServiceData"
  }
  pt.policy_table.functional_groupings.NewTestCaseGroup = { rpcs = { } }
  for _, v in pairs(additionalRPCs) do
    pt.policy_table.functional_groupings.NewTestCaseGroup.rpcs[v] = {
      hmi_levels = { "BACKGROUND", "FULL", "LIMITED" }
    }
  end
  pt.policy_table.app_policies.default.groups = { "Base-4", "NewTestCaseGroup" }
  actions.sdl.setPreloadedPT(pt)
end

--[[ @ignitionOff: Ignition Off sequence
--! @parameters:
--! pParam: name of the VD parameter
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

--[[ @openRPCservice: open RPC service
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.openRPCservice(pAppId)
  m.getMobileSession(pAppId):StartService(7)
end

--[[ @reRegisterApps: re-register 2 apps
--! @parameters:
--! pCheckResumptionData - verification function for resumption data
--! pErrorRpc - RPC name for error response
--! pErrorInterface - interface of RPC for error response
--! pRAIResponseExp - time for expectation of RAI response
--! @return: none
--]]
function m.reRegisterApps(pCheckResumptionData, pErrorRpc, pErrorInterface, pRAIResponseExp)
  local requestParams1 = m.cloneTable(m.getConfigAppParams(1))
  requestParams1.hashID = m.hashId[1]

  local requestParams2 = m.cloneTable(m.getConfigAppParams(2))
  requestParams2.hashID = m.hashId[2]

  if not pRAIResponseExp then pRAIResponseExp = 5000 end

  m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered")
  :Do(function(exp, d1)
      m.log("BC.OnAppRegistered " .. exp.occurences)
      if d1.params.appName == m.getConfigAppParams(1).appName then
        m.setHMIAppId(d1.params.application.appID, 1)
      else
        m.setHMIAppId(d1.params.application.appID, 2)
      end
      if exp.occurences == 1 then
        local corId2 = m.getMobileSession(2):SendRPC("RegisterAppInterface", requestParams2)
        m.log("RAI 2")
        m.getMobileSession(2):ExpectResponse(corId2, { success = true, resultCode = "SUCCESS" })
        :Do(function()
            m.log("SUCCESS: RAI 2")
            expOnHMIStatus(2, "FULL", pErrorRpc)
            m.getMobileSession(2):ExpectNotification("OnSystemCapabilityUpdated")
            m.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp", { appID = m.getHMIAppId(2) })
            :Do(function(_, data)
                m.getHMIConnection():SendResponse(data.id, "BasicCommunication.ActivateApp", "SUCCESS", {})
              end)
          end)
      end
      m.sendOnSCU(0, exp.occurences)
    end)
  :Times(2)

  local corId1 = m.getMobileSession(1):SendRPC("RegisterAppInterface", requestParams1)
  m.log("RAI 1")
  m.getMobileSession(1):ExpectResponse(corId1, { success = true, resultCode = "RESUME_FAILED" })
  :Do(function()
       m.log("RESUME_FAILED: RAI 1")
       expOnHMIStatus(1, "LIMITED", pErrorRpc)
       m.getMobileSession(1):ExpectNotification("OnSystemCapabilityUpdated")
    end)
  :Timeout(pRAIResponseExp)

  pCheckResumptionData(pErrorRpc, pErrorInterface)
end

--[[ @checkResumptionData2Apps: check resumption data for 2 apps
--! @parameters:
--! pErrorRpc - RPC name for error response
--! pErrorInterface - interface of RPC for error response
--! @return: none
--]]
function m.checkResumptionData2Apps(pErrorRpc, pErrorInterface)
  local uiSetGPtimes = 3
  local ttsSetGPtimes = 3
  if pErrorRpc == "setGlobalProperties" then
    if pErrorInterface == "UI" then
      uiSetGPtimes = 2
    else
      ttsSetGPtimes = 2
    end
  end

  local revertRpcToUpdate = m.cloneTable(m.removeData)
  revertRpcToUpdate.UnsubscribeWayPoints = nil

  if pErrorRpc == "addCommand" and pErrorInterface == "VR" then
    revertRpcToUpdate.DeleteVRCommand = nil
    m.removeData.DeleteVRCommand(1, "Choice", 1 )
  elseif pErrorRpc == "createIntrerationChoiceSet" then
    revertRpcToUpdate.DeleteVRCommand = nil
    m.removeData.DeleteVRCommand(1, "Command", 1 )
  elseif pErrorRpc == "addCommand" and pErrorInterface == "UI" then
    revertRpcToUpdate.DeleteUICommand = nil
  elseif pErrorRpc == "addSubMenu" then
      revertRpcToUpdate.DeleteSubMenu = nil
  elseif pErrorRpc == "subscribeVehicleData" then
      revertRpcToUpdate.UnsubscribeVehicleData = nil
  elseif pErrorRpc == "createWindow" then
    revertRpcToUpdate.DeleteWindow = nil
  end

  for k in pairs(revertRpcToUpdate) do
    revertRpcToUpdate[k](1)
  end

  m.getHMIConnection():ExpectRequest("VR.AddCommand")
  :Do(function(_, data)
      m.sendResponse2Apps(data, pErrorRpc, pErrorInterface)
    end)
  :Times(4)

  m.getHMIConnection():ExpectRequest("UI.AddCommand")
  :Do(function(_, data)
      m.sendResponse2Apps(data, pErrorRpc, pErrorInterface)
    end)
  :Times(2)

  m.getHMIConnection():ExpectRequest("UI.AddSubMenu")
  :Do(function(_, data)
      m.sendResponse2Apps(data, pErrorRpc, pErrorInterface)
    end)
  :Times(2)

  m.getHMIConnection():ExpectRequest("UI.SetGlobalProperties")
  :Do(function(_, data)
      m.sendResponse2Apps(data, pErrorRpc, pErrorInterface)
    end)
  :Times(uiSetGPtimes)

  m.getHMIConnection():ExpectRequest("TTS.SetGlobalProperties")
  :Do(function(_, data)
      m.sendResponse2Apps(data, pErrorRpc, pErrorInterface)
    end)
  :Times(ttsSetGPtimes)

  m.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData")
  :Do(function(_, data)
      m.sendResponse2Apps(data, pErrorRpc, pErrorInterface)
    end)
  :Times(2)

  m.getHMIConnection():ExpectRequest("UI.CreateWindow")
  :Do(function(exp, data)
      m.sendOnSCU(2, exp.occurences)
      m.sendResponse2Apps(data, pErrorRpc, pErrorInterface)
    end)
  :Times(2)
end

--[[ @ isResponseErroneous: define RPC for sending error response
--! @parameters:
--! pData - data from received request
--! pErrorRpc - RPC name for error response
--! pErrorInterface - interface of RPC for error response
--! @return: status of error response
--]]
local function isResponseErroneous(pData, pErrorRpc, pErrorInterface)
  local rpc = m.getRpcName(pErrorRpc, pErrorInterface)
  if pErrorRpc == "createIntrerationChoiceSet" then rpc = "VR.AddCommand" end
  if rpc == pData.method then
    if rpc ~= "VR.AddCommand" and pErrorRpc ~= "setGlobalProperties" then
      return true
    elseif pErrorRpc == "createIntrerationChoiceSet" and pData.params.type == "Choice" then
      return true
    elseif pErrorRpc == "addCommand" and pData.params.type == "Command" then
      return true
    elseif pErrorRpc == "setGlobalProperties" then
      local helpPromptText = "Help prompt1"
      local vrHelpTitle ="VR help title1"
      if pData.method == "TTS.SetGlobalProperties" then
        if pErrorInterface == "TTS" and pData.params.helpPrompt[1].text == helpPromptText then
          return true
        end
      else
        if pErrorInterface == "UI" and pData.params.vrHelpTitle == vrHelpTitle then
          return true
        end
      end
    end
  end
  return false
end

--[[ @errorResponse: sending error response
--! @parameters:
--! pData - data from received request
--! @return: none
--]]
function m.errorResponse(pData)
  m.getHMIConnection():SendError(pData.id, pData.method, "GENERIC_ERROR", "info message")
end

--[[ @sendResponse2Apps: sending error response
--! @parameters:
--! pData - data from received request
--! pErrorRpc - RPC name for error response
--! pErrorInterface - interface of RPC for error response
--! @return: none
--]]
function m.sendResponse2Apps(pData, pErrorRpc, pErrorInterface)
  local isErrorResponse = isResponseErroneous(pData, pErrorRpc, pErrorInterface)
  if pData.method == "VehicleInfo.SubscribeVehicleData" and pErrorRpc == "subscribeVehicleData" and pData.params.gps then
    m.errorResponse(pData)
  elseif pData.params.appID == m.getHMIAppId(1) and isErrorResponse == true then
    m.errorResponse(pData)
  else
    m.getHMIConnection():SendResponse(pData.id, pData.method, "SUCCESS", {})
  end
end

--[[ @activateNotAudibleApp: activation of non-media app
--! @parameters:none
--! @return: none
--]]
function m.activateNotAudibleApp()
  local requestId = m.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = m.getHMIAppId() })
  m.getHMIConnection():ExpectResponse(requestId)
  m.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
end

--[[ @deactivateAppToLimited: deactivate app to LIMITED HMI level
--! @parameters:none
--! @return: none
--]]
function m.deactivateAppToLimited()
  m.getHMIConnection():SendNotification("BasicCommunication.OnAppDeactivated", {
      appID = m.getHMIAppId()
    })
  m.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
end

--[[ @deactivateAppToBackground: deactivate app to BACKGROUND HMI level
--! @parameters:none
--! @return: none
--]]
function m.deactivateAppToBackground()
  m.getHMIConnection():SendNotification("BasicCommunication.OnAppDeactivated", {
      appID = m.getHMIAppId()
    })
  m.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
end

--[[ @splitString: split string with separator
--! @parameters:
--! pInputStr - string
--! pSep - separator
--! @return: none
--]]
function m.splitString(pInputStr, pSep)
  if pSep == nil then
    pSep = "%s"
  end
  local splitted, i = {}, 1
  for str in string.gmatch(pInputStr, "([^"..pSep.."]+)") do
    splitted[i] = str
    i = i + 1
  end
  return splitted
end

--[[ @log: print text to console
--! @parameters:
--! ... - set of strings to print (e.g. 'aaa', 'bbb' etc.)
--! @return: none
--]]
function m.log(...)
  local str = "[" .. atf_logger.formated_time(true) .. "]"
  for i, p in pairs({...}) do
    local delimiter = "\t"
    if i == 1 then delimiter = " " end
    str = str .. delimiter .. p
  end
  utils.cprint(color.magenta, str)
end

--[[ @sendOnSCU: Send BC.OnSystemCapabilityUpdated for window
--! @parameters:
--! pWinId - window identifier (0, 1, etc.)
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.sendOnSCU(pWinId, pAppId)
  if not pAppId then pAppId = 1 end
  local params = getOnSCUParams({ pWinId })
  params.appID = m.getHMIAppId(pAppId)
  m.getHMIConnection():SendNotification("BasicCommunication.OnSystemCapabilityUpdated", params)
end

--[[ @createWindow: adding of window
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.createWindow(pAppId)
  if not pAppId then pAppId = 1 end
  local params = {
    windowID = 2,
    windowName = "Name",
    type = "WIDGET",
    associatedServiceType = "MEDIA"
  }
  local cid = m.getMobileSession(pAppId):SendRPC("CreateWindow", params)
  m.getHMIConnection():ExpectRequest("UI.CreateWindow")
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      m.resumptionData[pAppId].createWindow = { UI = data.params }
    end)
  m.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_, data)
      m.hashId[pAppId] = data.payload.hashID
    end)
end

--[[ @sendOnButtonPress: send OnButtonEvent and OnButtonPress
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pIsExp - true (default) - if it's expected notification on mobile app
--! @return: none
--]]
function m.sendOnButtonPress(pAppId, pIsExp)
  if pAppId == nil then pAppId = 1 end
  local occurences = pIsExp == true and 1 or 0
  local btnName = "OK"
  local btnEventMode = "BUTTONDOWN"
  local btnPressMode = "SHORT"
  m.getMobileSession(pAppId):ExpectNotification("OnButtonEvent",
    { buttonName = btnName, buttonEventMode = btnEventMode })
  :Times(occurences)
  m.getMobileSession(pAppId):ExpectNotification("OnButtonPress",
    { buttonName = btnName, buttonPressMode = btnPressMode })
  :Times(occurences)
  m.getHMIConnection():SendNotification("Buttons.OnButtonEvent",
    { name = btnName, appID = m.getHMIAppId(pAppId), mode = btnEventMode })
  m.getHMIConnection():SendNotification("Buttons.OnButtonPress",
    { name = btnName, appID = m.getHMIAppId(pAppId), mode = btnPressMode })
end

--[[ @sendOnVehicleData: send OnVehicleData
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pIsExp - true (default) - if it's expected notification on mobile app
--! @return: none
--]]
function m.sendOnVehicleData(pAppId, pIsExp)
  if pAppId == nil then pAppId = 1 end
  local occurences = pIsExp == true and 1 or 0
  local params = {
    gps = {
      longitudeDegrees = 10,
      latitudeDegrees = 10
    }
  }
  m.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", params)
  m.getMobileSession(pAppId):ExpectNotification("OnVehicleData", params):Times(occurences)
end

--[[ @checkResumptionDataSuccess: verify resumption for successful scenario
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.checkResumptionDataSuccess(pAppId)
  m.addSubMenuResumption(pAppId)
  m.setGlobalPropertiesResumption(pAppId)
  m.subscribeVehicleDataResumption(pAppId)
  m.subscribeWayPointsResumption(pAppId)
  m.createWindowResumption(pAppId)
  m.getHMIConnection():ExpectRequest("UI.AddCommand",
    m.resumptionData[pAppId].addCommand.UI)
  :Do(function(_, data)
      m.sendResponse(data)
    end)
  m.getHMIConnection():ExpectRequest("VR.AddCommand",
    m.resumptionData[pAppId].addCommand.VR,
    m.resumptionData[pAppId].createIntrerationChoiceSet.VR)
  :Do(function(_, data)
      m.sendResponse(data)
    end)
  :Times(2)

  local isCustomButtonSubscribed = false
  local isOkButtonSubscribed = false
  m.getHMIConnection():ExpectNotification("Buttons.OnButtonSubscription")
  :ValidIf(function(_, data)
      if data.params.name == "CUSTOM_BUTTON" and isCustomButtonSubscribed == false then
        isCustomButtonSubscribed = true
      elseif data.params.name == "OK" and data.params.isSubscribed == true and isOkButtonSubscribed == false then
        isOkButtonSubscribed = true
      else
        return false, "Came unexpected Buttons.OnButtonSubscription notification"
      end
      return true
    end)
  :Times(2)
end

--[[ @checkSubscriptions: verify subscriptions to Button events and Vehicle data
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pIsExp - true (default) - if it's expected notification on mobile app
--! @return: none
--]]
function m.checkSubscriptions(pIsExp, pAppId)
  m.sendOnButtonPress(pAppId, pIsExp)
  m.sendOnVehicleData(pAppId, pIsExp)
end

return m
