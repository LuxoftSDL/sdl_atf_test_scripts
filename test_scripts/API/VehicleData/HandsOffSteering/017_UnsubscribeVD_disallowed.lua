---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Check that SDL rejects UnsubscribeVehicleData request with resultCode: "DISALLOWED" if an app not allowed by
-- policy with new 'handsOffSteering' parameter
--
-- Preconditions:
-- 1) Update preloaded_pt file, add handsOffSteering parameter to VD_RPC group
-- 2) RPC SubscribeVehicleData is allowed by policies
-- 3) RPC UnsubscribeVehicleData is Not allowed by policies
-- 4) App is registered and subscribed on handsOffSteering parameter
-- Steps:
-- 1) App sends valid UnsubscribeVehicleData request to SDL
-- SDL does:
-- - a) send UnsubscribeVehicleData response with (success = false, resultCode = DISALLOWED") to App
-- - b) not transfer this request to HMI
-- - c) not send OnHashChange notification to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')
local json = require("modules/json")

--[[ Local Variables ]]
local rpc_sub = "SubscribeVehicleData"
local rpc_unsub = "UnsubscribeVehicleData"
local VDGroup = {
  rpcs = {
    SubscribeVehicleData = {
      hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
      parameters = {"handsOffSteering"}
    },
    UnsubscribeVehicleData = {
      hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
      parameters = json.EMPTY_ARRAY
    }
  }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.precondition)
common.Step("Update preloaded file", common.updatedPreloadedPTFile, { VDGroup })
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerAppWOPTU)
common.Step("RPC " .. rpc_sub .. " on handsOffSteering parameter", common.processRPCSuccess, { rpc_sub })

common.Title("Test")
common.Step("RPC " .. rpc_unsub .. " on handsOffSteering parameter DISALLOWED",
  common.processRPCDisallowed, { rpc_unsub })

common.Title("Postconditions")
common.Step("Stop SDL", common.postcondition)
