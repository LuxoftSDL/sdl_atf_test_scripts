---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local paramsToExclude = { "make","model", "modelYear", "trim", "systemHardwareVersion" }

--[[ Local Functions ]]
local function setHMICap(pParamsToExclude)
  local out = common.setHMIcap(common.vehicleTypeInfoParams.default)
  for _, value in pairs(pParamsToExclude) do
    for key in pairs(out.VehicleInfo.GetVehicleType.params.vehicleType) do
      if key == value then out.VehicleInfo.GetVehicleType.params.vehicleType[key] = nil end
    end
    for key in pairs(out.BasicCommunication.GetSystemInfo.params) do
      if key == value then out.BasicCommunication.GetSystemInfo.params[key] = nil end
    end
  end
  return out
end

local function startRpcService(pAckParams, pNotExpected)
  common.startRpcService(pAckParams)
  :ValidIf(function(_, data)
    local errorMessages = ""
    local actPayload = common.bson_to_table(data.binaryData)
    for _, param in pairs(pNotExpected) do
      for Key, _ in pairs(actPayload) do
        if Key == param then
          errorMessages = errorMessages .. "BinaryData contains unexpected " .. param .. " parameter\n"
        end
      end
    end
    if string.len(errorMessages) > 0 then
      return false, errorMessages
    else
      return true
    end
  end)
end

--[[ Scenario ]]
common.Title("Test with excluding all not mandatory parameters")
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
local hmiCap = setHMICap(paramsToExclude)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { hmiCap })

common.Title("Test")
common.Step("Vehicle type data without all not mandatory params in StartServiceAck", startRpcService,
  { common.getRpcServiceAckParams(hmiCap), paramsToExclude })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
