------------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0205-Avoid_custom_button_subscription_when_HMI_does_not_support.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check that SDL sends SubscribeButton RPC with 'CUSTOM_BUTTON' parameter parameter during resumption
--  after Ignition Cycle in case:
--  - 'CUSTOM_BUTTON' is missing in the hmi_capabilities.json file
--  - 'CUSTOM_BUTTON' becomes not supported by HMI after Ignition cycle
------------------------------------------------------------------------------------------------------------------------
-- Preconditions:
-- 1. CUSTOM_BUTTON is missing in the hmi_capabilities.json
-- 2. SDL and HMI are started
-- 3. HMI supported CUSTOM_BUTTON (SDL receives Buttons.GetCapabilities response from HMI with supported CUSTOM_BUTTON)
-- 4. Mobile app is registered and activated
-- In case:
-- 1. IGN_OFF and IGN_ON are performed
-- 2. HMI sends GetSystemInfo with new ccpu_version_2 to SDL
-- 3. HMI doesn't support CUSTOM_BUTTON (HMI sends Buttons.GetCapabilities response without CUSTOM_BUTTON)
-- 4. App re-registered with actual HashId
-- SDL does:
-- - send request Buttons.SubscribeButtons(CUSTOM_BUTTON) to HMI
-- - wait respond Buttons.SubscribeButtons(SUCCESS) from HMI
-- - receive Buttons.SubscribeButton(SUCCESS)
-- - not send OnHashChange with updated hashId to mobile app
-- In case:
-- 5. HMI sends OnButtonEvent and OnButtonPress notifications to SDL
-- SL does:
-- - resend OnButtonEvent and OnButtonPress notifications to mobile App for CUSTOM_BUTTON
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/ButtonSubscription/commonButtonSubscription')

--[[ Local Variables ]]
local appSessionId1 = 1
local buttonName = "CUSTOM_BUTTON"
local isCacheNotUsed = false

--[[ Local Functions ]]
local function checkResumptionData(pAppId)
  common.getHMIConnection():ExpectRequest("Buttons.SubscribeButton",
    { appID = common.getHMIAppId(pAppId), buttonName = "CUSTOM_BUTTON" })
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  common.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Times(0)
end

local function updateHMISystemInfo(pVersion)
  local hmiValues = common.getDefaultHMITable()
  hmiValues.BasicCommunication.GetSystemInfo = {
    params = {
      ccpu_version = pVersion,
      language = "EN-US",
      wersCountryCode = "wersCountryCode"
    }
  }
  return hmiValues
end

local function removeButtonFromCapabilities(pButtonName, pVersion)
  local hmiValues = updateHMISystemInfo(pVersion)
  for i, buttonNameTab in pairs(hmiValues.Buttons.GetCapabilities.params.capabilities) do
    if (buttonNameTab.name == pButtonName) then
      table.remove(hmiValues.Buttons.GetCapabilities.params.capabilities, i)
    end
  end
  return hmiValues
end

local function addButtonToCapabilities(pButtonCapabilities, pVersion)
  local hmiValues = updateHMISystemInfo(pVersion)
  for i, buttonNameTab in pairs(hmiValues.Buttons.GetCapabilities.params.capabilities) do
    if (buttonNameTab.name == pButtonCapabilities.name) then
      table.remove(hmiValues.Buttons.GetCapabilities.params.capabilities, i)
    end
  end
  table.insert(hmiValues.Buttons.GetCapabilities.params.capabilities, pButtonCapabilities)
  return hmiValues
end

--[[ Scenario ]]
common.runner.Title("Preconditions")
common.runner.Step("Clean environment", common.preconditions)
common.runner.Step("Remove CUSTOM_BUTTON from hmi_capabilities.json",
  common.removeButtonFromHMICapabilitiesFile, { buttonName })
common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start,
  { addButtonToCapabilities(common.customButtonCapabilities, "cppu_version_1") })
common.runner.Step("App registration and send Subscribe CUSTOM_BUTTON", common.registerAppSubCustomButton)
common.runner.Step("App activation", common.activateApp)
common.runner.Step("Subscribe on Soft button", common.registerSoftButton)
common.runner.Step("IGNITION OFF", common.ignitionOff)
common.runner.Step("IGNITION ON, HMI sends different cppu_version", common.startCacheUsed,
  { removeButtonFromCapabilities(common.customButtonCapabilities, "cppu_version_2"), isCacheNotUsed  })

common.runner.Title("Test")
common.runner.Step("Reregister App resumption data", common.reRegisterAppSuccess,
  { appSessionId1, checkResumptionData, common.resumptionFullHMILevel })
common.runner.Step("Subscribe on Soft button", common.registerSoftButton)
common.runner.Step("On Custom_button press", common.buttonPress,
  { appSessionId1, buttonName, common.isExpected, common.customButtonID })

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
