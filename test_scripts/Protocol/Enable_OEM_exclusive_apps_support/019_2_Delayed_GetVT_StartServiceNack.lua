--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local hmiCap = common.setHMIcap(common.vehicleTypeInfoParams.default)
hmiCap.VehicleInfo.GetVehicleType.delay = 3000

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)

common.Title("Test")
common.Step("Start SDL, HMI, connect Mobile, start Session", common.startWithExtension,
  { hmiCap, common.nackExtensionForStart })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
