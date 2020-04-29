---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL receive DATA_ALREADY_SUBSCRIBED to SubscribeVehicleData request if App already subscribed
--
-- Preconditions:
-- 1) Update preloaded_pt file, add handsOffSteering parameter to VD_RPC group
-- 2) RPC SubscribeVehicleData is allowed by policies
-- 3) App is registered and subscribed on handsOffSteering VD
-- Steps:
-- 1) App sends valid SubscribeVehicleData request to SDL
-- SDL does:
-- - a) send SubscribeVehicleData response with (success = false, resultCode = DATA_ALREADY_SUBSCRIBED") to App
-- - b) send OnHashChange notification to App
-- - c) not transfer this request to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Variable ]]
local rpc = "SubscribeVehicleData"

--[[ Local function ]]
local function appAlreadySubscribed(pRpcName)
  local cid = common.getMobileSession():SendRPC(pRpcName, { handsOffSteering = true })
  common.getHMIConnection():ExpectRequest("VehicleInfo" .. pRpcName) :Times(0)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "IGNORED",
    handsOffSteering = {dataType = "VEHICLEDATA_HANDSOFFSTEERING", resultCode = "DATA_ALREADY_SUBSCRIBED"}, })
  common.getMobileSession():ExpectNotification("OnHashChange") :Times(0)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.precondition)
common.Step("Update preloaded file", common.updatedPreloadedPTFile)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerAppWOPTU)
common.Step("RPC " .. rpc .. " on handsOffSteering parameter", common.processRPCSuccess, { rpc })

common.Title("Test")
common.Step("App sends RPC " .. rpc .. " on already subscribed parameter", appAlreadySubscribed, { rpc })

common.Title("Postconditions")
common.Step("Stop SDL", common.postcondition)
