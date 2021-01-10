---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")
local utils = require("user_modules/utils")
if not utils.isFileExist("lib/bson4lua.so") then
  common.skipTest("'bson4lua' library is not available in ATF")
  common.Step("Skipping test")
  return
end

--[[ Local Variables ]]
local hmiCap = common.setHMIcap(common.vehicleTypeInfoParams.default)
local rpcServiceAckParams = common.getRpcServiceAckParams(hmiCap)

local rpcServiceParams = {
  reqParams = {
    protocolVersion = { type = common.bsonType.STRING, value = "5.3.0" }
  }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Init SDL certificates", common.initSDLCertificates, { "./files/Security/client_credential.pem" , true })
common.Step("Start SDL, HMI, connect Mobile, start Session", common.startWithCustomCap, { hmiCap })
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("Switch RPC Service to Protected mode ACK",
  common.startServiceProtectedACK, { 1, common.serviceType.RPC, rpcServiceParams.reqParams, rpcServiceAckParams })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
