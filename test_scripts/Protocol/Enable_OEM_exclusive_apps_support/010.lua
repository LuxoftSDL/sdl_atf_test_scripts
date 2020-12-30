---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Test Configuration ]]
common.testSettings.restrictions.sdlBuildOptions = {{ extendedPolicy = { "EXTERNAL_PROPRIETARY" }}}

--[[ Local Variables ]]
local hmiCap = common.getHmiCap()
local systemHardwareVersion = hmiCap.BasicCommunication.GetSystemInfo.params.systemInfoParams.systemHardwareVersion

local function verifyPTSnapshot()
  local ptsTable = common.ptsTable()
  local hardware_version = ptsTable.policy_table.module_meta.hardware_version
  if not ptsTable then
    common.failTestStep("Policy table snapshot was not created")
  elseif not common.isTableEqual(hardware_version, systemHardwareVersion ) then
    common.failTestStep("Incorrect systemHardwareVersion value\n" ..
      " Expected: " .. systemHardwareVersion  .. "\n" ..
      " Actual: " .. tostring(hardware_version) .. "\n" )
  end
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.startWithCustomCap, { hmiCap })

common.Title("Test")
common.Step("Register App, PTU is triggered", common.registerApp)
common.Step("Check that PTS contains systemHardwareVersion", verifyPTSnapshot)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
