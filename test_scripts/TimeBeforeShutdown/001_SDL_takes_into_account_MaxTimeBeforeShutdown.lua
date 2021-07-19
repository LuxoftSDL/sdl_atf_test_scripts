----------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0117-configurable-time-before-shutdown.md
--
-- Description: Check SDL takes into account the value of 'MaxTimeBeforeShutdown' parameter during shut down sequence
-- in case if 'FlushLogMessagesBeforeShutdown' = true
--
-- In case:
-- 1. In SDL .ini 'FlushLogMessagesBeforeShutdown' = true and 'MaxTimeBeforeShutdown' = 10
-- 2. HMI sends 'BC.OnExitAllApplications(IGNITION_OFF)' notification to SDL
-- SDL does:
--  - shut down within 'MaxTimeBeforeShutdown' duration.
--  - not wait until all logs are written
----------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/TimeBeforeShutdown/common')

--[[ Conditions to skip test ]]
common.isTestApplicable()

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Set SDL .ini params", common.setSDLIniParams, {
  { FlushLogMessagesBeforeShutdown = "true", MaxTimeBeforeShutdown = 10 } })

common.Title("Test")
common.Step("Start SDL, init HMI", common.start)
common.Step("Ignition Off", common.ignitionOff, { 10 })
common.Step("Check SDL log is not complete", common.checkSDLLog, { common.logNotComplete })

common.Title("Postconditions")
common.Step("Clean environment", common.postconditions)
