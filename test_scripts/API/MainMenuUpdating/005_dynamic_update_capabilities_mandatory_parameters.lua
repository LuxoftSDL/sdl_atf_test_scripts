---------------------------------------------------------------------------------------------------
-- Description:
-- HMI sends capability with DynamicUpdateCapabilities parameter

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level

-- Steps:
-- HMI sends DISPLAYS system capability update with Dynamic Update capabilities
-- a. without non-mandatory supportedDynamicImageFieldNames parameter
-- b. without non-mandatory supportsDynamicSubMenus parameter

-- Expected:
-- Mobile receives capability update with correct params.
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local onSystemCapabilityUpdatedParams = {
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
            maximumNumberOfWindows = 2
          }
        },
        windowCapabilities = {
          {
            dynamicUpdateCapabilities = {
                supportedDynamicImageFieldNames = {"subMenuIcon", "menuIcon"},
                supportsDynamicSubMenus = true
            },
            menuLayoutsAvailable = { "LIST", "TILES" },
            textFields = {
              {
                name = "mainField1",
                characterSet = "TYPE2SET",
                width = 1,
                rows = 1
              }
            },
            imageFields = {
              {
                name = "choiceImage",
                imageTypeSupported = { "GRAPHIC_PNG"
                },
                imageResolution = {
                  resolutionWidth = 35,
                  resolutionHeight = 35
                }
              }
            },
            imageTypeSupported = {
              "STATIC"
            },
            templatesAvailable = {
              "Template1", "Template2", "Template3", "Template4", "Template5"
            },
            numCustomPresetsAvailable = 100,
            buttonCapabilities = {
              {
                longPressAvailable = true,
                name = "VOLUME_UP",
                shortPressAvailable = true,
                upDownAvailable = false
              }
            },
            softButtonCapabilities = {
              {
                shortPressAvailable = true,
                longPressAvailable = true,
                upDownAvailable = true,
                imageSupported = true,
                textSupported = true
              }
            }
          }
        }
      }
    }
  }
}

--[[ Local Functions ]]
local function updateDisplayCapabilities(param, value)
  local mobileSession = common.getMobileSession()
  local hmi = common.getHMIConnection()
  onSystemCapabilityUpdatedParams.appID = common.getHMIAppId()
  local onSCUP =common.cloneTable(onSystemCapabilityUpdatedParams)
  onSCUP.systemCapability.displayCapabilities[1].windowCapabilities[1].dynamicUpdateCapabilities[param] = value
  hmi:SendNotification("BasicCommunication.OnSystemCapabilityUpdated", onSCUP)

  onSCUP.appID = nil
  mobileSession:ExpectNotification("OnSystemCapabilityUpdated", onSCUP)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Sending Dynamic Update Capabilities without supportedDynamicImageFieldNames", updateDisplayCapabilities,
  { "supportedDynamicImageFieldNames", nil })
runner.Step("Sending Dynamic Update Capabilities without supportsDynamicSubMenus", updateDisplayCapabilities,
  { "supportsDynamicSubMenus", nil })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
