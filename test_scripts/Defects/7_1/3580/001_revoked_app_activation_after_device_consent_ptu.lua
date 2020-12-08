---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3580
--
-- Description: Check that SDL does not activate revoked application after device consent.
-- Application is revoked via PTU in current ignition cycle
--
-- Preconditions:
-- 1. SDL built with EXTERNAL_PROPRIETARY policy option
-- 2  The application has no permissions in policy table
-- 3. SDL and HMI are started
-- 4. Device 1 and Device 2 are connected to SDL (Device 1 is consented, Device 2 is not consented)
-- 5. The application from Device 1 is registered
-- 6. PTU is performed. The application is set as revoked (null permissions) via PTU.
--
-- Sequence:
-- 1. Try to activate the application from Device 1 via SDL.ActivateApp request from HMI
--   a. SDL does not activate the application from Device 1 and respond to SDL.ActivateApp
--    with isSDLAllowed = true and isAppRevoked = true parameters
-- 2. Register the same application from Device 2
--   a. SDL sucessfully register the application from Device 2
-- 3. Try to activate the application from Device 2 via SDL.ActivateApp request from HMI
--   a. SDL does not activate the application from Device 1 and respond to SDL.ActivateApp
--    with isSDLAllowed = false and isAppRevoked = true parameters
-- 4. Consent Device 2 from HMI via SDL.OnAllowSDLFunctionality
--   a. SDL does not activate the application from Device 2
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Defects/7_1/3580/common')

--[[ Test Configuration ]]
common.testSettings.restrictions.sdlBuildOptions = {{extendedPolicy = {"EXTERNAL_PROPRIETARY"}}}

--[[ Local Data ]]
local devices = {
  [1] = { host = "1.0.0.1", port = config.mobilePort, hasAutoConsent = true },
  [2] = { host = "192.168.100.199", port = config.mobilePort, hasAutoConsent = false },
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL and HMI", common.startWithoutMobile)
common.Step("Connect two mobile devices to SDL", common.connectMobDevices, { devices })
common.Step("Register App1 from device 1", common.registerApp, { 1, 1 })
common.Step("Revoke app via PTU", common.revokeAppViaPtu)

common.Title("Test")
common.Step("Activate App1 on device 1 with device consent", common.activateRevokedApp, { 1, true })
common.Step("Register App1 from device 2", common.registerAppNoPTU, { 2, 2 })
common.Step("Activate App1 on device 2 without device consent", common.activateRevokedApp, { 2, false })
common.Step("Allow SDL for Device 2", common.consentDevice, { 2 })

common.Title("Postconditions")
common.Step("Remove mobile devices", common.clearMobDevices, { devices })
common.Step("Stop SDL", common.postconditions)
