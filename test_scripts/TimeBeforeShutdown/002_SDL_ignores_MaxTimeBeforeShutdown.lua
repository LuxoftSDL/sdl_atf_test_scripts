----------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0117-configurable-time-before-shutdown.md
--
-- Description: Check SDL ignores the value of 'MaxTimeBeforeShutdown' parameter during shut down sequence
-- in case if 'FlushLogMessagesBeforeShutdown' = false
--
-- In case:
-- 1. In SDL .ini 'FlushLogMessagesBeforeShutdown' = false and 'MaxTimeBeforeShutdown' = 10
-- 2. HMI sends 'BC.OnExitAllApplications(IGNITION_OFF)' notification to SDL
-- SDL does:
--  - shut down without timeout (as soon as possible)
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
  { FlushLogMessagesBeforeShutdown = "false", MaxTimeBeforeShutdown = 10 } })

common.Title("Test")
common.Step("Start SDL, init HMI", common.start)
common.Step("Ignition Off", common.ignitionOff, { 1 })
common.Step("Check SDL log is not complete", common.checkSDLLog, { common.logNotComplete })

common.Title("Postconditions")
common.Step("Clean environment", common.postconditions)
