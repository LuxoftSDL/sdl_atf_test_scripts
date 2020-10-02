---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0202-character-sets.md
--
-- Description: Check that the SDL sends appropriate cached CharacterSet values in RegisterAppInterface response
--  to mobile app
--
-- Preconditions: TBD
-- Sequence TBD
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/SupportedCharacterSets/commonCharacterSets')

--[[ Scenario ]]
for _, characterSetValue in common.spairs(common.characterSets) do
  common.Title("Preconditions")
  common.Step("Clean environment", common.preconditions)
  common.Step("Start SDL and HMI, SDL sends capabilities requests to HMI", common.start,
    { common.getHMITableWithUpdCharacterSet(characterSetValue) })
  common.Step("Ignition Off", common.ignitionOff)

  common.Title("Test")
  common.Step("Start SDL and HMI, SDL does not send capabilities requests to HMI", common.start,
    { common.getHMIParamsWithOutRequests() })
  common.Step("RAI with characterSet=" .. characterSetValue, common.registerApp, { characterSetValue })

  common.Title("Postconditions")
  common.Step("Stop SDL", common.postconditions)
end
