---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local hmicap = common.getCapWithMandatoryExp()
local getVehicleTypeParams = hmicap.VehicleInfo.GetVehicleType.params.vehicleType
getVehicleTypeParams.make = "Ford"
getVehicleTypeParams.model = "Focus"
getVehicleTypeParams.modelYear = 2015
getVehicleTypeParams.trim = "SEL"

local getSystemInfoParams = hmicap.BasicCommunication.GetSystemInfo.params
getSystemInfoParams.ccpu_version = "12345_TV"
getSystemInfoParams.systemHardwareVersion = "V4567_GJK"

local rpcServiceParams = {
  reqParams = {
    protocolVersion = common.setStringBsonValue("5.3.0")
  },
  ackParams = common.getRpcServiceAckParams(hmicap)
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.startWithCustomCap, { hmicap })

common.Title("Test")
common.Step("Start RPC Service, Vehicle type data in StartServiceAck", common.startServiceUnprotectedACK,
  { 1, common.serviceType.RPC, rpcServiceParams.reqParams, rpcServiceParams.ackParams })
common.Step("EndService", common.endRPCSevice)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
