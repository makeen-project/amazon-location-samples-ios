import XCTest

final class ConfigUITests : UITests { 
    func testCognitoConfigurationPersistence() {
        launchApp(withConfiguration: false)

        app.tabBars.buttons["Config"].tap()
        app.buttons["CognitoConfiguration"].tap()
        
        // Fill in all the values in the Cognito Configuration
        let identityPoolIDTextField = app.textFields["IdentityPoolID"]
        identityPoolIDTextField.tap()
        identityPoolIDTextField.typeText(sampleIdentityPoolID)
        
        
        let mapNameTextField = app.textFields["MapName"]
        mapNameTextField.tap()
        mapNameTextField.typeText(sampleMapName)
        
        let trackerNameTextField = app.textFields["TrackerName"]
        trackerNameTextField.tap()
        trackerNameTextField.typeText(sampleTrackerName)
        
        let websocketURLTextField = app.textFields["WebsocketURL"]
        websocketURLTextField.tap()
        websocketURLTextField.typeText(sampleWebsocketURL)
        
        let geofenceCollectionARNTextField = app.textFields["GeofenceCollectionARN"]
        geofenceCollectionARNTextField.tap()
        geofenceCollectionARNTextField.typeText(sampleGeofenceCollectionARN)

        app.buttons["SaveConfiguration"].tap()
        
        allowPermission()

        // Restart the app
        app.terminate()
        app.launchArguments = []
        app.launch()
        
        // Check the values are still present
        app.tabBars.buttons["Config"].tap()
        app.buttons["CognitoConfiguration"].tap()
        
        XCTAssertEqual(app.textFields["IdentityPoolID"].value as! String, sampleIdentityPoolID)
        XCTAssertEqual(app.textFields["MapName"].value as! String, sampleMapName)
        XCTAssertEqual(app.textFields["TrackerName"].value as! String, sampleTrackerName)
        XCTAssertEqual(app.textFields["WebsocketURL"].value as! String, sampleWebsocketURL)
        XCTAssertEqual(app.textFields["GeofenceCollectionARN"].value as! String, sampleGeofenceCollectionARN)
        
        app.buttons["SaveConfiguration"].tap()
    }
    
    func testToggleFilters() {
        launchApp()

        XCTAssertTrue(app.steppers["TimeFilterStepper"].waitForExistence(timeout: 5))
        let timeFilterSwitch = app.switches["TimeFilterToggle"]
        turnSwitchOff(timeFilterSwitch)
        XCTAssertFalse(app.steppers["TimeFilterStepper"].waitForExistence(timeout: 5))
        
        let distanceFilterSwitch = app.switches["DistanceFilterToggle"]
        turnSwitchOn(distanceFilterSwitch)
        XCTAssertTrue(app.steppers["DistanceFilterStepper"].waitForExistence(timeout: 5))
        
        let accuracyFilterSwitch = app.switches["AccuracyFilterToggle"]
        turnSwitchOn(accuracyFilterSwitch)
        XCTAssertEqual(accuracyFilterSwitch.value as? String, "1")
    }
    
    func testAdjustTimeFilter() {
        launchApp()

        let timeStepper = app.steppers["TimeFilterStepper"]
        let initialStepperValue = timeStepper.value as? String
        XCTAssertEqual(initialStepperValue, "30")
        timeStepper.buttons["Seconds: 30, Increment"].tap()
        let finalStepperValue = timeStepper.value as? String
        XCTAssertNotEqual(initialStepperValue, finalStepperValue)
    }

    func testAdjustDistanceFilter() {
        launchApp()
        
        let distanceFilterSwitch = app.switches["DistanceFilterToggle"]
        turnSwitchOn(distanceFilterSwitch)
        
        let distanceStepper = app.steppers["DistanceFilterStepper"]
        let initialStepperValue = distanceStepper.value as? String
        distanceStepper.buttons["Meters: 30, Increment"].tap()
        let finalStepperValue = distanceStepper.value as? String
        XCTAssertNotEqual(initialStepperValue, finalStepperValue)
    }

    func testAccuracyFilter() {
        launchApp()
        
        let accuracyFilterSwitch = app.switches["AccuracyFilterToggle"]
        let initialState = accuracyFilterSwitch.value as? String
        turnSwitchOn(accuracyFilterSwitch)
        let finalState = accuracyFilterSwitch.value as? String
        XCTAssertNotEqual(initialState, finalState)
    }
}
