---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Test Configuration ]]
config.defaultProtocolVersion = 4 -- Set 4 protocol as default for script

--[[ Local Variables ]]
local hmiCap = common.setHMIcap(common.vehicleTypeInfoParams.default)

--[[ Local Functions ]]
local function registerApp(responseExpectedData, pAppId)
  if not pAppId then pAppId = 1 end
  local session = common.createSession(pAppId)
  session:StartService(7)
  :Do(function()
     common.registerAppEx(responseExpectedData, pAppId)
  end)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.startWithCustomCap, { hmiCap })

common.Title("Test")
common.Step("Vehicle type data in RAI", registerApp, { common.vehicleTypeInfoParams.default })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
