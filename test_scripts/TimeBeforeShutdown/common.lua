---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local actions = require('user_modules/sequences/actions')
local utils = require("user_modules/utils")
local atf_logger = require("atf_logger")
local color = require("user_modules/consts").color
local SDL = require('SDL')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.ExitOnCrash = false
config.defaultProtocolVersion = 3

--[[ Module ]]
local m = {}

--[[ Common Proxy Functions ]]
do
  m.Title = runner.Title
  m.Step = runner.Step
  m.skipTest = runner.skipTest
end

--[[ Common Constants ]]
m.logComplete = true
m.logNotComplete = false

--[[ Local Constants ]]
local ping = 1000 --ms
local timeout = 120000
local delay = 5000
local fsFileName = "slowfile"
local slowDriveDir = "slowdrv"
local slowDevice = "dm-slow"
local sdlLogFileParamName = "log4j.appender.SmartDeviceLinkCoreLogFile.File"

--[[ Local Variables ]]
local loopDevice
local sdlLogFileParamCurrentValue
local sdlLogFileParamNewValue
local ts_start
local ts_finish

--[[ Module Functions ]]
function m.log(...)
  local str = "[" .. atf_logger.formated_time(true) .. "]"
  for i, p in pairs({...}) do
    local delimiter = "\t"
    if i == 1 then delimiter = " " end
    str = str .. delimiter .. tostring(p)
  end
  utils.cprint(color.magenta, str)
end

function m.execCMD(pCmd)
  local handle = io.popen(pCmd)
  local result = handle:read("*a")
  handle:close()
  return (string.gsub(result, "\n", ""))
end

local function getSDLLogInfo()
  return m.execCMD("wc -l -c " .. sdlLogFileParamNewValue .. " | awk '{print $1,$2}'")
end

function m.ignitionOff(pExpDuration)
  local event = actions.run.createEvent()
  actions.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  actions.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
      actions.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "IGNITION_OFF" })
      m.log("BC.OnExitAllApplications")
      ts_start = timestamp()
      actions.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLClose")
      :Do(function()
          m.log("BC.OnSDLClose")
        end)
      local pid = m.execCMD("cat sdl.pid")
      m.log("SDL pid:", pid)
      local pCnt = 0
      local function waitForShutdown()
        if actions.sdl.isRunning() then
          pCnt = pCnt + 1
          m.log(".", pCnt, getSDLLogInfo())
          actions.run.runAfter(waitForShutdown, ping)
        else
          SDL.DeleteFile()
          ts_finish = timestamp()
          local actualDuration = (ts_finish - ts_start) / 1000
          local tolerance = 1.5 -- s
          m.log("SDL stopped, shutdown duration (s):", actualDuration)
          actions.getHMIConnection():RaiseEvent(event, "SDL stop event")
          if pExpDuration ~= nil
            and (actualDuration > pExpDuration + tolerance or actualDuration < pExpDuration - tolerance) then
            actions.run.fail("Expected shut down duration (s): " .. pExpDuration)
          end
          return
        end
      end
      actions.run.runAfter(waitForShutdown, ping)
    end)
  actions.getHMIConnection():ExpectEvent(event, "SDL stop event")
  :Timeout(timeout)
end

function m.start()
  local event = actions.run.createEvent()
  actions.init.SDL()
  :Do(function()
      actions.init.HMI()
      :Do(function()
          actions.hmi.getConnection():RaiseEvent(event, "Start event")
          actions.run.wait(delay)
        end)
    end)
  return actions.hmi.getConnection():ExpectEvent(event, "Start event")
end

function m.createSlowDrive()
  local id = m.execCMD("sudo dmsetup ls | awk '{print $1}' | sort -r | head -n 1 | cut -d'_' -f2")
  if id == "No" then id = 0 end
  id = id + 1
  m.log("DeviceId:", id)
  fsFileName = fsFileName .. "_" .. id
  slowDriveDir = slowDriveDir .. "_" .. id
  slowDevice = slowDevice .. "_" .. id
  m.execCMD("dd if=/dev/zero of=./" .. fsFileName .. " bs=512k count=10")
  loopDevice = m.execCMD("sudo losetup --show --find " .. fsFileName)
  m.log("Device:", loopDevice)
  local size = m.execCMD("sudo blockdev --getsize " .. loopDevice)
  m.log("Size:", size)
  m.execCMD("sudo dmsetup create " .. slowDevice .. " --table '0 " .. size .. " delay " .. loopDevice .. " 0 1'"
    .. " && sudo mkfs.ext2 -F -O ^has_journal /dev/mapper/" .. slowDevice
    .. " && mkdir -p " .. slowDriveDir
    .. " && sudo mount -o discard,relatime,sync /dev/mapper/".. slowDevice .. " " .. slowDriveDir
    .. " && sudo chown -R `id -u`:`id -g` " .. slowDriveDir)
  m.log(m.execCMD("sudo dmsetup ls"))
  m.log(m.execCMD("dd if=/dev/zero of=" .. slowDriveDir .. "/speed_test count=100; rm " .. slowDriveDir .. "/speed_test;"))
end

function m.removeSlowDrive()
  m.execCMD("sudo umount -f /dev/mapper/" .. slowDevice
    .. " && sleep 1"
    .. " && sudo dmsetup remove " .. slowDevice
    .. " && sudo losetup -d " .. loopDevice)
  m.execCMD("rm -rf " .. fsFileName)
  m.execCMD("rm -rf " .. slowDriveDir)
end

function m.updateSDLLoggerConfig()
  sdlLogFileParamCurrentValue = SDL.LOGGER.get(sdlLogFileParamName)
  sdlLogFileParamNewValue = m.execCMD("pwd") .. "/" .. slowDriveDir .. "/" .. sdlLogFileParamCurrentValue
  SDL.LOGGER.set(sdlLogFileParamName, sdlLogFileParamNewValue
    .. "\n" .. "log4j.appender.SmartDeviceLinkCoreLogFile.Threshold=DEBUG")
end

function m.restoreSDLLoggerConfig()
  SDL.LOGGER.set(sdlLogFileParamName, sdlLogFileParamCurrentValue)
end

function m.copySDLLog()
  os.execute("cp " .. sdlLogFileParamNewValue .. " " .. config.pathToSDL)
end

function m.preconditions()
  actions.preconditions()
  m.createSlowDrive()
  m.updateSDLLoggerConfig()
end

function m.postconditions()
  m.copySDLLog()
  actions.postconditions()
  m.removeSlowDrive()
  m.restoreSDLLoggerConfig()
end

function m.setSDLIniParams(pParamValues)
  for p, v in pairs(pParamValues) do
    actions.sdl.setSDLIniParameter(p, v)
  end
end

function m.checkSDLLog(pExpLogState)
  local successMsg = "Application has been stopped successfuly"
  local res = m.execCMD("grep '" .. successMsg .. "' " .. sdlLogFileParamNewValue .. " | wc -l")
  local actualLogState = res == "1" and true or false
  if actualLogState ~= pExpLogState then
    actions.run.fail("SDL log is expected to be " .. (pExpLogState and "complete" or "not complete"))
  end
end

function m.isTestApplicable()
  if m.execCMD("grep :/docker /proc/self/cgroup | wc -l") ~= "0" then
    runner.skipTest("Script is unable to be run in parallel mode (docker container)")
  end
end

return m
