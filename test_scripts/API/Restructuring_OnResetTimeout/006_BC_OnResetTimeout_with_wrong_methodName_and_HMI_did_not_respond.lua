------------------------------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check SDL is able to respond with GENERIC_ERROR:false to Mobile app in case:
--  - wrong 'methodName' is provided in 'OnResetTimeout()' notification from HMI
--  - and default reset period is expired
--  - and HMI hasn't responded
-- Applicable RPCs: 'SendLocation', 'Alert', 'SubtleAlert', 'PerformInteraction', 'Slider', 'Speak',
--  'ScrollableMessage', 'DiagnosticMessage', 'SetInteriorVehicleData'
------------------------------------------------------------------------------------------------------------------------
-- Preconditions:
-- 1) Default SDL timeout is 10s (defined in .INI by 'DefaultTimeout' parameter)
--
-- In case:
-- 1) App sends applicable RPC
-- 2) SDL transfers this request to HMI
-- 3) HMI sends 'BC.OnResetTimeout' notification with wrong 'methodName' to SDL right after receiving request
-- 4) HMI doesn't provide a response
-- SDL does:
--  - wait for the response from HMI within
--    - '2 x default timeout' (20s) for 'GetInteriorVehicleDataConsent'
--    - 'default timeout' (10s) for all other requests
--  - respond with GENERIC_ERROR:false to Mobile app once this timeout expires
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')

--[[ Local Variables ]]
local wrongMethodName = "Wrong_methodName"

local paramsForRespFunction = {
  notificationTime = 6000,
  resetPeriod = 6000
}

local paramsForRespFunctionWithConsent = {
  notificationTime = 6000,
  resetPeriod = 16000
}

local rpcResponse = { success = false, resultCode = "GENERIC_ERROR" }

--[[ Local Functions ]]
local function invalidParamOnResetTimeout(pData, pOnRTParams)
  local function sendOnResetTimeout()
    common.onResetTimeoutNotification(pData.id, wrongMethodName, pOnRTParams.resetPeriod)
  end
  RUN_AFTER(sendOnResetTimeout, pOnRTParams.notificationTime)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App_1 registration", common.registerAppWOPTU)
common.Step("App_2 registration", common.registerAppWOPTU, { 2 })
common.Step("App_1 activation", common.activateApp)
common.Step("Set RA mode: ASK_DRIVER", common.defineRAMode, { true, "ASK_DRIVER" })
common.Step("Create InteractionChoiceSet id 100", common.createInteractionChoiceSet, { 100 })
common.Step("Create InteractionChoiceSet id 200", common.createInteractionChoiceSet, { 200 })
common.Step("Add AddSubMenu", common.addSubMenu)

common.Title("Test")
for _, rpc in pairs(common.rpcsArrayWithoutRPCWithCustomTimeout) do
  common.Step("Send " .. rpc , common.rpcs[rpc],
    { 11000, 10000, invalidParamOnResetTimeout, paramsForRespFunction, rpcResponse, common.responseTimeCalculationFromMobReq })
end
common.Step("Send PerformInteraction" , common.rpcs.PerformInteraction,
  { 16000, 15000, invalidParamOnResetTimeout, paramsForRespFunction, rpcResponse, common.responseTimeCalculationFromMobReq })
common.Step("Send ScrollableMessage" , common.rpcs.ScrollableMessage,
  { 12000, 11000, invalidParamOnResetTimeout, paramsForRespFunction, rpcResponse, common.responseTimeCalculationFromMobReq })
common.Step("Send Alert" , common.rpcs.Alert,
  { 14000, 13000, invalidParamOnResetTimeout, paramsForRespFunction, rpcResponse, common.responseTimeCalculationFromMobReq })
common.Step("Send SubtleAlert" , common.rpcs.SubtleAlert,
  { 14000, 13000, invalidParamOnResetTimeout, paramsForRespFunction, rpcResponse, common.responseTimeCalculationFromMobReq })
common.Step("Send Slider" , common.rpcs.Slider,
  { 12000, 11000, invalidParamOnResetTimeout, paramsForRespFunction, rpcResponse, common.responseTimeCalculationFromMobReq })

common.Step("Module allocation for App_1" , common.rpcAllowed, { "CLIMATE", 1, "SetInteriorVehicleData" })
common.Step("App_2 activation", common.activateApp, { 2 })
common.Step("Send SetInteriorVehicleData with consent" , common.rpcs.rpcAllowedWithConsent,
  { 21000, 20000, invalidParamOnResetTimeout, paramsForRespFunctionWithConsent, rpcResponse, common.responseTimeCalculationFromMobReq })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
