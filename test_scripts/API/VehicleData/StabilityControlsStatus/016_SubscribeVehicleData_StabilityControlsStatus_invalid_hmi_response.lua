---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0253-New-vehicle-data-StabilityControlsStatus.md
--
-- Description: Check subscription on StabilityControlsStatus data via SubscribeVehicleData RPC
--   with invalid HMI response
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) App is registered
-- 3) PTU is successfully performed, all vehicle data is allowed
-- 4) App is activated

-- Steps:
-- 1) App sends SubscribeVehicleData request with (stabilityControlsStatus = true) to SDL
-- SDL sends VehicleInfo.SubscribeVehicleData request with (stabilityControlsStatus = true) to HMI
-- HMI sends VehicleInfo.SubscribeVehicleData response and
--   - stabilityControlsStatus is an empty structure
--   - stabilityControlsStatus contains invalid values
--   - stabilityControlsStatus is of an incorrect type
--   - stabilityControlsStatus is not a structure
-- SDL sends SubscribeVehicleData response with (success: false, resultCode: "GENERIC_ERROR",
--   info: "Invalid message received from vehicle")
-- 2) HMI sends VehicleInfo.OnVehicleData notifications with StabilityControlsStatus data
-- SDL does not send OnVehicleData notification with received from HMI data to App
-- 3) App sends SubscribeVehicleData request with (stabilityControlsStatus = true) to SDL
-- SDL sends VehicleInfo.SubscribeVehicleData request with (stabilityControlsStatus = true) to HMI
-- HMI sends invalid VehicleInfo.SubscribeVehicleData response and stabilityControlsStatus is absent
-- SDL sends SubscribeVehicleData response with (success: false, resultCode: "GENERIC_ERROR",
--   info: "Subscription failed for some Vehicle data")
-- 4) HMI sends VehicleInfo.OnVehicleData notifications with StabilityControlsStatus data
-- SDL does not send OnVehicleData notification with received from HMI data to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/commonVehicleData')

--[[ Test Configuration ]]
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 6
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 2

--[[ Local variables ]]
local vdNameInvalidRes = "stabilityControlsStatus"
local mobileRequest = {
  [vdNameInvalidRes] = true
}
local hmiRequest = mobileRequest

local hmiResponseEmpty = {
  [vdNameInvalidRes] = {},
}
local hmiResponseInvalidValues = {
  [vdNameInvalidRes] = { resultCode = "SUCCESS", dataType = "invalidType" },
}
local hmiResponseAbsent = {}
local hmiResponseIncorrectType = {
  -- mandatory parameter 'dataType' is missing
  [vdNameInvalidRes] = { resultCode = "SUCCESS" },
}
local hmiResponseNotAStructure = {
  [vdNameInvalidRes] = 1,
}
local mobileResponse = {
  success = false,
  resultCode = "GENERIC_ERROR",
  info = "Invalid message received from vehicle"
}
local mobileResponseAbsent = {
  success = false,
  resultCode = "GENERIC_ERROR",
  info = "Subscription failed for some Vehicle data"
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, init HMI, connect default mobile", common.start)
common.Step("Register App", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { common.ptUpdate })
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("Subscribe on VehicleData, invalid HMI response: empty structure",
  common.processSubscribeVD, { mobileRequest, hmiRequest, hmiResponseEmpty, mobileResponse })
common.Step("Ignore OnVehicleData with " .. vdNameInvalidRes .. " data",
  common.checkNotificationIgnored, {{ vdNameInvalidRes }})

common.Step("Subscribe on VehicleData, invalid HMI response: invalid values",
  common.processSubscribeVD, { mobileRequest, hmiRequest, hmiResponseInvalidValues, mobileResponse })
common.Step("Ignore OnVehicleData with " .. vdNameInvalidRes .. " data",
  common.checkNotificationIgnored, {{ vdNameInvalidRes }})

common.Step("Subscribe on VehicleData, invalid HMI response: incorrect type",
  common.processSubscribeVD, { mobileRequest, hmiRequest, hmiResponseIncorrectType, mobileResponse })
common.Step("Ignore OnVehicleData with " .. vdNameInvalidRes .. " data",
  common.checkNotificationIgnored, {{ vdNameInvalidRes }})

common.Step("Subscribe on VehicleData, invalid HMI response: not a structure",
  common.processSubscribeVD, { mobileRequest, hmiRequest, hmiResponseNotAStructure, mobileResponse })
common.Step("Ignore OnVehicleData with " .. vdNameInvalidRes .. " data",
  common.checkNotificationIgnored, {{ vdNameInvalidRes }})

common.Step("Subscribe on VehicleData, invalid HMI response: structure is absent",
  common.processSubscribeVD, { mobileRequest, hmiRequest, hmiResponseAbsent, mobileResponseAbsent })
common.Step("Ignore OnVehicleData with " .. vdNameInvalidRes .. " data",
  common.checkNotificationIgnored, {{ vdNameInvalidRes }})

common.Title("Postconditions")
common.Step("Stop SDL, restore environment", common.postconditions)
