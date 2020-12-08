---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3580
--
-- Description: Check that SDL does not activate revoked application after device consent.
-- Application is revoked via PTU in previous ignition cycle
--
-- Preconditions:
-- 1. SDL built with EXTERNAL_PROPRIETARY policy option
-- 2. The application is set as revoked (null permissions) via PTU in one of the previous ignition cycles
-- 3. SDL and HMI are started
-- 4. Not consented device is connected to SDL
-- 5. The application is registered
--
-- Sequence:
-- 1. Try to activate the application via SDL.ActivateApp request from HMI
--   a. SDL does not activate the application and respond to SDL.ActivateApp
--    with isSDLAllowed = false and isAppRevoked = true parameters
-- 2. Consent device from HMI via SDL.OnAllowSDLFunctionality
--   a. SDL does not activate the application
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Defects/7_1/3580/common')

--[[ Test Configuration ]]
common.testSettings.restrictions.sdlBuildOptions = {{extendedPolicy = {"EXTERNAL_PROPRIETARY"}}}

--[[ Local Data ]]
local devices = {
  [1] = { host = "1.0.0.1", port = config.mobilePort, hasAutoConsent = false }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL and HMI", common.startWithoutMobile)
common.Step("Connect mobile device to SDL", common.connectMobDevices, { devices })
common.Step("Allow SDL for device 1", common.allowSDL, { 1 })
common.Step("Register App1 from device 1", common.registerApp, { 1, 1 })
common.Step("Revoke app via PTU", common.revokeAppViaPtu)
common.Step("Disallow SDL for device 1", common.disallowSDL, { 1 })
common.Step("Ignition off", common.ignitionOff)
common.Step("Start SDL and HMI", common.startWithoutMobile)
common.Step("Connect mobile device to SDL", common.connectMobDevices, { devices })
common.Step("Register App1 from device 1", common.registerAppNoPTU, { 1, false })

common.Title("Test")
common.Step("Activate App1 on device 1 without device consent", common.activateRevokedApp, { 1, false })
common.Step("Allow SDL for device 1", common.consentDevice, { 1 })

common.Title("Postconditions")
common.Step("Remove mobile devices", common.clearMobDevices, { devices })
common.Step("Stop SDL", common.postconditions)
