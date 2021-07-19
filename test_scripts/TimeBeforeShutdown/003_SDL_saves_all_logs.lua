----------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0117-configurable-time-before-shutdown.md
--
-- Description: Check SDL is able to save all logs during shut down sequence
-- if the value of 'MaxTimeBeforeShutdown' parameter is big enough and 'FlushLogMessagesBeforeShutdown' = true
--
-- In case:
-- 1. In SDL .ini 'FlushLogMessagesBeforeShutdown' = true and 'MaxTimeBeforeShutdown' = 60
-- 2. HMI sends 'BC.OnExitAllApplications(IGNITION_OFF)' notification to SDL
-- SDL does:
--  - shut down once all logs are written
----------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/TimeBeforeShutdown/common')

--[[ Conditions to skip test ]]
common.isTestApplicable()

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Set SDL .ini params", common.setSDLIniParams, {
  { FlushLogMessagesBeforeShutdown = "true", MaxTimeBeforeShutdown = 60 } })

common.Title("Test")
common.Step("Start SDL, init HMI", common.start)
common.Step("Ignition Off", common.ignitionOff, { nil })
common.Step("Check SDL log is complete", common.checkSDLLog, { common.logComplete })

common.Title("Postconditions")
common.Step("Clean environment", common.postconditions)
