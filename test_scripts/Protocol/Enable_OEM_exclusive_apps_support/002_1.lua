---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local paramsToExclude = { "make", "model", "modelYear", "trim", "systemHardwareVersion" }

--[[ Local Functions ]]
local function setHMICap(pParamToExclude)
  local defaultVehicleTypeInfoParam = common.cloneTable(common.vehicleTypeInfoParams.default)
  defaultVehicleTypeInfoParam[pParamToExclude] = nil
  local out = common.setHMIcap(defaultVehicleTypeInfoParam)
  return out
end

local function startRpcService(pAckParams, pNotExpected)
  common.startRpcService(pAckParams)
  :ValidIf(function(_, data)
    local errorMessages = ""
    local actPayload = common.bson_to_table(data.binaryData)
    for Key, _ in pairs(actPayload) do
      if Key == pNotExpected then
        errorMessages = errorMessages .. "BinaryData contains unexpected " .. pNotExpected .. " parameter\n"
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
for _, parameter in common.spairs(paramsToExclude) do
  common.Title("Test with excluding " .. parameter .. " parameter")
  common.Title("Preconditions")
  common.Step("Clean environment", common.preconditions)
  local hmiCap = setHMICap(parameter)
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { hmiCap })

  common.Title("Test")
  common.Step("Vehicle type data without " .. parameter .. " in StartServiceAck", startRpcService,
    { common.getRpcServiceAckParams(hmiCap), parameter })

  common.Title("Postconditions")
  common.Step("Stop SDL", common.postconditions)
end
