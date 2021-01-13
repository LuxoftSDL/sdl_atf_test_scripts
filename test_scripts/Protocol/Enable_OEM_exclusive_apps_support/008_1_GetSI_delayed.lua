---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL is able to postpone sending of StartServiceAck in case HMI responds with delay to
--  BC.GetSystemInfo request, VI.GetVehicleType is also requested and HMI responds immediately to
--  VI.GetVehicleType request
--
-- Steps:
-- 1. SDL requests BC.GetSystemInfo and VI.GetVehicleType to HMI after start
-- 2. App requests StartService(RPC) via 5th protocol
-- SDL does:
--  - Postpone the sending of StartServiceAck before receiving of BC.GetSystemInfo and VI.GetVehicleType responses
-- 3. HMI responds with delay to BC.GetSystemInfo request and immediately to VI.GetVehicleType request
-- SDL does:
--  - Send StartServiceAck after receiving VI.GetVehicleType and BC.GetSystemInfo responses
--  - Provide the vehicle type data received from HMI in BC.GetSystemInfo and VI.GetVehicleType responses
--     in StartServiceAck to the app
-- 4. App requests RAI
-- SDL does:
--  - Provide the vehicle type data received from HMI in BC.GetSystemInfo and VI.GetVehicleType responses
--     in RAI response to the app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local delay1 = 3000
local delay2 = 0
local hmiCap = common.setHMIcap(common.vehicleTypeInfoParams.default)

--[[ Local Functions ]]
local function start()
  local function check()
    common.delayedStartServiceAckP5(hmiCap, delay1, delay2)
  end
  common.startWithExtension(check)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)

common.Title("Test")
common.Step("Start SDL, HMI, connect Mobile, start Session, send StartService", start)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
