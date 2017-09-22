---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/26
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/embedded_navi/Subscribe_to_Destination_and_Waypoints.md
-- Item: Use Case 1: Main Flow
--
-- Requirement summary:
-- [SubscribeWayPoints] As a mobile app I want to be able to subscribe on notifications about
-- any changes to the destination or waypoints.
--
-- Description:
-- In case:
-- 1) mobile application sent valid and allowed by Policies SubscribeWayPoints_request to SDL
--
-- SDL must:
-- 1) transfer SubscribeWayPoints_request_ to HMI
-- 2) respond with <resultCode> received from HMI to mobile app

---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonNavigation = require('test_scripts/API/Navigation/commonNavigation')

--[[ Local Variables ]]
local notification = {
  wayPoints = {
    {
      coordinate = {
        latitudeDegrees = 1.1,
        longitudeDegrees = 1.1
      }
    }
  }
}

--[[ Local Functions ]]
local function subscribeWayPointsFirstApp(self)
  local cid = self.mobileSession1:SendRPC("SubscribeWayPoints", {})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  self.mobileSession1:ExpectResponse(cid, { success = true , resultCode = "SUCCESS" })
  self.mobileSession1:ExpectNotification("OnHashChange")
end

local function subscribeWayPointsSecondApp(self)
  local cid = self.mobileSession2:SendRPC("SubscribeWayPoints", {})
  self.mobileSession2:ExpectResponse(cid, { success = true , resultCode = "SUCCESS" })
  self.mobileSession2:ExpectNotification("OnHashChange")
end

local function onWayPointChangeToBothApps(self)
  self.hmiConnection:SendNotification("Navigation.OnWayPointChange", notification)
  self.mobileSession1:ExpectNotification("OnWayPointChange", notification)
  self.mobileSession2:ExpectNotification("OnWayPointChange", notification)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonNavigation.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonNavigation.start)
runner.Step("RAI, PTU", commonNavigation.registerAppWithPTU)
runner.Step("Activate App", commonNavigation.activateApp)
runner.Step("RAI, PTU", commonNavigation.registerAppWithPTU, { 2 })
runner.Step("Activate App", commonNavigation.activateApp, { 2 })

runner.Title("Test")
runner.Step("SubscribeWayPoints first app", subscribeWayPointsFirstApp)
runner.Step("SubscribeWayPoints second app", subscribeWayPointsSecondApp)
runner.Step("OnWayPointChange to check apps subscription", onWayPointChangeToBothApps)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonNavigation.postconditions)
