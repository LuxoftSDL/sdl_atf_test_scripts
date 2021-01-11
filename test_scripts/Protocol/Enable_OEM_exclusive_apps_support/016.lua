---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local hmiCap = common.setHMIcap(common.vehicleTypeInfoParams.default)

local videoServiceParams = {
  reqParams = {
    height        = { type = common.bsonType.INT32,  value = 350 },
    width         = { type = common.bsonType.INT32,  value = 800 },
    videoProtocol = { type = common.bsonType.STRING, value = "RAW" },
    videoCodec    = { type = common.bsonType.STRING, value = "H264" }
  }
}

local audioServiceParams = {
  reqParams = {
    mtu = { type = common.bsonType.INT64,  value = 131072 }
  }
}

--[[ Local Functions ]]
local function setVideoConfig()
  common.getHMIConnection():ExpectRequest("Navigation.SetVideoConfig")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { hmiCap })

common.Title("Test")
common.Step("Register App", common.registerAppUpdatedProtocolVersion)
common.Step("Activate App", common.activateApp)
common.Step("Start unprotected Video Service, ACK", common.startServiceUnprotectedACK,
  { 1, common.serviceType.VIDEO, videoServiceParams.reqParams, videoServiceParams.reqParams, setVideoConfig })
common.Step("Start unprotected Audio Service, ACK", common.startServiceUnprotectedACK,
  { 1, common.serviceType.PCM, audioServiceParams.reqParams, audioServiceParams.reqParams })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
