---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local vehicleTypeData = {
  make = "Ford",
  model = "Focus",
  modelYear = "2015",
  trim = "SEL",
  ccpu_version = "12345_TV",
  systemHardwareVersion = "V4567_GJK"
}
local hmicap = common.setHMIcap(vehicleTypeData)
local rpcServiceAckParams = common.getRpcServiceAckParams(hmicap)

--[[ Local Functions ]]
local function unregisterAppInterface()
  local cid = common.getMobileSession():SendRPC("UnregisterAppInterface",{})
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.startWithCustomCap, { hmicap })

common.Title("Test")
common.Step("Start RPC Service, Vehicle type data in StartServiceAck", common.startRpcService, { rpcServiceAckParams })
common.Step("RAI, Vehicle type data in StartServiceAck", common.registerApp, { vehicleTypeData })
common.Step("UnregisterAppInterface", unregisterAppInterface)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
