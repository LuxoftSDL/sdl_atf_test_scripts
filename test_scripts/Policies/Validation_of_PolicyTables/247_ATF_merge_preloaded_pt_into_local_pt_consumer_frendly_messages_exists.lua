---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] Merging rules for "consumer_friendly_messages" section - exists in LocalPT and does NOT exist in PreloadedPT
-- --
-- Description:
-- Check of merging rules for "consumer_friendly_messages" section in case when section exists in LocalPT and does NOT exist in PreloadedPT
-- 1. Used preconditions
-- Delete files and policy table from previous ignition cycle if any
-- Start SDL with PreloadedPT json file with "preloaded_date" parameter and 2 language sections(de-de and en-us)
-- as child of "consumer_friendly_messages"

-- 2. Performed steps
-- Stop SDL
-- Start SDL with corrected PreloadedPT json file with "preloaded_date" parameter with bigger value
-- and 1 language sections(en-us) as child of "consumer_friendly_messages"
--
-- Expected result:
-- SDL must leave fields&values of "consumer_friendly_messages" section in LocalPT base without changes
---------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require ('user_modules/shared_testcases/commonPreconditions')
local testCasesForPolicyTable = require ('user_modules/shared_testcases/testCasesForPolicyTable')
local json = require("modules/json")

--[[ Local Variables ]]
local TESTED_DATA = {
  {
    key = "de-de",
    label = "Fahrzeuginformationen",
    tts = "Eine App hat Zugriff auf die folgenden Fahrzeuginformationen: Kraftstoff-Füllstand, Kraftstoffverbrauch, Motordrehzahl, Kilometerzähler, FIN, Außentemperatur, Gangstellung, Reifenluftdruck."
  },
  {
    key = "en-us",
    label = "Vehicle information",
    tts = "An app can access the following vehicle information: Fuel Level, Fuel Economy, Engine RPMs, Odometer, VIN, External Temperature, Gear Position, Tire Pressure."
  },
  preloaded_date = {"2000-10-01","2016-01-01"}
}
local PRELOADED_PT_FILE_NAME = "sdl_preloaded_pt.json"

local TestData = {
  path = config.pathToSDL .. "TestData",
  isExist = false,
  init = function(self)
    if not self.isExist then
      os.execute("mkdir ".. self.path)
      os.execute("echo 'List test data files files:' > " .. self.path .. "/index.txt")
      self.isExist = true
    end
  end,
  store = function(self, message, pathToFile, fileName)
    if self.isExist then
      local dataToWrite = message

      if pathToFile and fileName then
        os.execute(table.concat({"cp ", pathToFile, " ", self.path, "/", fileName}))
        dataToWrite = table.concat({dataToWrite, " File: ", fileName})
      end

      dataToWrite = dataToWrite .. "\n"
      local file = io.open(self.path .. "/index.txt", "a+")
      file:write(dataToWrite)
      file:close()
    end
  end,
  delete = function(self)
    if self.isExist then
      os.execute("rm -r -f " .. self.path)
      self.isExist = false
    end
  end,
  info = function(self)
    if self.isExist then
      commonFunctions:userPrint(35, "All test data generated by this test were stored to folder: " .. self.path)
    else
      commonFunctions:userPrint(35, "No test data were stored" )
    end
  end
}

--[[ Local Functions ]]
local function updatePreloadedPt(updaters)
  local pathToFile = config.pathToSDL .. PRELOADED_PT_FILE_NAME
  local file = io.open(pathToFile, "r")
  local json_data = file:read("*a")
  file:close()

  local data = json.decode(json_data)
  if data then
    for _, updateFunc in pairs(updaters) do
      updateFunc(data)
    end
  end

  local dataToWrite = json.encode(data)
  file = io.open(pathToFile, "w")
  file:write(dataToWrite)
  file:close()
end

local function prepareNewPreloadedPT()
  local newUpdaters = {
    function(data)
      for key, value in pairs(data.policy_table.functional_groupings) do
        if not value.rpcs then
          data.policy_table.functional_groupings[key] = nil
        end
      end
    end,
    function(data)
      data.policy_table.module_config.preloaded_date = TESTED_DATA.preloaded_date[2]
    end,
    function(data)
      for key,_ in pairs(data.policy_table.consumer_friendly_messages.messages.VehicleInfo.languages) do
        if key ~= "en-us" then
          data.policy_table.consumer_friendly_messages.messages.VehicleInfo.languages[key] = nil
        end
      end
    end
  }
  updatePreloadedPt(newUpdaters)
end

local function prepareInitialPreloadedPT()
  local initialUpdaters = {
    function(data)
      for key, value in pairs(data.policy_table.functional_groupings) do
        if not value.rpcs then
          data.policy_table.functional_groupings[key] = nil
        end
      end
    end,
    function(data)
      data.policy_table.module_config.preloaded_date = TESTED_DATA.preloaded_date[1]
    end,
    function(data)
      for key,_ in pairs(data.policy_table.consumer_friendly_messages.messages.VehicleInfo.languages) do
        if key ~= TESTED_DATA[1].key and key ~= TESTED_DATA[2].key then
          data.policy_table.consumer_friendly_messages.messages.VehicleInfo.languages[key] = nil
        end
      end
    end
  }
  updatePreloadedPt(initialUpdaters)
end

local function constructPathToDatabase()
  if commonSteps:file_exists(config.pathToSDL .. "storage/policy.sqlite") then
    return config.pathToSDL .. "storage/policy.sqlite"
  elseif commonSteps:file_exists(config.pathToSDL .. "policy.sqlite") then
    return config.pathToSDL .. "policy.sqlite"
  else
    commonFunctions:userPrint(31, "policy.sqlite is not found" )
    return nil
  end
end

local function executeSqliteQuery(rawQueryString, dbFilePath)
  if not dbFilePath then
    return nil
  end
  local queryExecutionResult = {}
  local queryString = table.concat({"sqlite3 ", dbFilePath, " '", rawQueryString, "'"})
  local file = io.popen(queryString, 'r')
  if file then
    local index = 1
    for line in file:lines() do
      queryExecutionResult[index] = line
      index = index + 1
    end
    file:close()
    return queryExecutionResult
  else
    return nil
  end
end

local function isValuesCorrect(actualValues, expectedValues)
  if #actualValues ~= #expectedValues then
    return false
  end

  local tmpExpectedValues = {}
  for i = 1, #expectedValues do
    tmpExpectedValues[i] = expectedValues[i]
  end

  local isFound
  for j = 1, #actualValues do
    isFound = false
    for key, value in pairs(tmpExpectedValues) do
      if value == actualValues[j] then
        isFound = true
        tmpExpectedValues[key] = nil
        break
      end
    end
    if not isFound then
      return false
    end
  end
  if next(tmpExpectedValues) then
    return false
  end
  return true
end

--[[ General Precondition before ATF start ]]
config.defaultProtocolVersion = 2
testCasesForPolicyTable.Delete_Policy_table_snapshot()
commonSteps:DeleteLogsFileAndPolicyTable()
commonPreconditions:BackupFile(PRELOADED_PT_FILE_NAME)
prepareInitialPreloadedPT()

--[[ General configuration parameters ]]
Test = require('connecttest')
require('user_modules/AppTypes')

function Test.checkLocalPT(checkTable)
  local expectedLocalPtValues
  local queryString
  local actualLocalPtValues
  local comparationResult
  local isTestPass = true
  for _, check in pairs(checkTable) do
    expectedLocalPtValues = check.expectedValues
    queryString = check.query
    actualLocalPtValues = executeSqliteQuery(queryString, constructPathToDatabase())
    if actualLocalPtValues then
      comparationResult = isValuesCorrect(actualLocalPtValues, expectedLocalPtValues)
      commonFunctions:userPrint(35, "ExpectedLocalPtValues")
      for _, values in pairs(expectedLocalPtValues) do
        print(values)
      end
      commonFunctions:userPrint(35, "ActualLocalPtValues")
      for _, values in pairs(actualLocalPtValues) do
        print(values)
      end
      if not comparationResult then
        --TestData:store(table.concat({"Test ", queryString, " failed: SDL has wrong values in LocalPT"}))
        --TestData:store("ExpectedLocalPtValues")
        commonFunctions:userPrint(31, table.concat({"Test ", queryString, " failed: SDL has wrong values in LocalPT"}))
        isTestPass = false
      end
    else
      --TestData:store("Test failed: Can't get data from LocalPT")
      commonFunctions:userPrint(31, "Test failed: Can't get data from LocalPT")
      isTestPass = false
    end
  end
  return isTestPass
end

--[[Precondition]]
function Test.Precondition()
  TestData:init()
  --TestData:store("Initial preloaded PT is stored", config.pathToSDL .. PRELOADED_PT_FILE_NAME, "initial_" .. PRELOADED_PT_FILE_NAME)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_VerifyInitialLocalPT()
  os.execute("sleep 3")
  --TestData:store("Initial Local PT is stored", constructPathToDatabase(), "initial_policy.sqlite")
  local checks = {
    {
      query = 'select preloaded_date from module_config',
      expectedValues = {TESTED_DATA.preloaded_date[1]}
    },
    {
      query = 'select language_code from message where message_type_name = "VehicleInfo"',
      expectedValues = {TESTED_DATA[1].key, TESTED_DATA[2].key}
    },
    {
      query = 'select tts from message where message_type_name = "VehicleInfo"',
      expectedValues = {TESTED_DATA[1].tts, TESTED_DATA[2].tts}
    },
    {
      query = 'select label from message where message_type_name = "VehicleInfo"',
      expectedValues = {TESTED_DATA[1].label, TESTED_DATA[2].label}
    }
  }
  if not self.checkLocalPT(checks) then
    self:FailTestCase("SDL has wrong values in LocalPT")
  end
end

function Test:TestStep_StopSDL()
  StopSDL(self)
end

function Test.TestStep_LoadNewPreloadedPT()
  prepareNewPreloadedPT()
  --TestData:store("New preloaded PT is stored", config.pathToSDL .. PRELOADED_PT_FILE_NAME, "new_" .. PRELOADED_PT_FILE_NAME)
end

function Test:TestStep_StartSDL()
  StartSDL(config.pathToSDL, true, self)
end

function Test:TestStep_VerifyNewLocalPT()
  os.execute("sleep 3")
  --TestData:store("New Local PT is stored", constructPathToDatabase(), "new_policy.sqlite")
  local checks = {
    {
      query = 'select preloaded_date from module_config',
      expectedValues = {TESTED_DATA.preloaded_date[2]}
    },
    {
      query = 'select language_code from message where message_type_name = "VehicleInfo"',
      expectedValues = {TESTED_DATA[2].key}
    },
    {
      query = 'select tts from message where message_type_name = "VehicleInfo"',
      expectedValues = {TESTED_DATA[2].tts}
    },
    {
      query = 'select label from message where message_type_name = "VehicleInfo"',
      expectedValues = {TESTED_DATA[2].label}
    }
  }
  if not self.checkLocalPT(checks) then
    self:FailTestCase("SDL has wrong values in LocalPT")
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
testCasesForPolicyTable:Restore_preloaded_pt()
function Test.Postcondition()
  StopSDL()
  --TestData:info()
end

return Test
