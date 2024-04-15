import XCTest
import CoreLocation

final class TrackingUITests : UITests {
    func testNoConfigurationState() {
        launchApp(withConfiguration: false)

        let tabBarsQuery = app.tabBars
        tabBarsQuery.buttons["Tracking"].tap()
        XCTAssertTrue(app.staticTexts["Please enter configuration"].exists)
    }
    
    func testMapAndTrackingButton() throws {
        launchApp()
        
        app.tabBars.buttons["Tracking"].tap()

        let mapView = app.otherElements["MapView"]
        XCTAssertTrue(mapView.waitForExistence(timeout: 10), "Map view did not load in time")

        let trackingButton = app.buttons["TrackingButton"]
        XCTAssertTrue(trackingButton.exists, "Tracking button did not load")
        trackingButton.tap()
    }
    
    func testTracking() throws {
        XCUIDevice.shared.location = XCUILocation(location:  CLLocation(latitude: 33.930338, longitude: -118.368004))
        launchApp()
        
        app.tabBars.buttons["Tracking"].tap()
        sleep(5)
        app.buttons["TrackingButton"].tap()
        
        XCUIDevice.shared.location = XCUILocation(location: CLLocation(latitude: 33.930338, longitude: -118.368004))
        sleep(5)
        XCUIDevice.shared.location = XCUILocation(location: CLLocation(latitude: 33.933171, longitude: -118.356971))
        sleep(5)
        XCUIDevice.shared.location = XCUILocation(location: CLLocation(latitude: 33.929322, longitude: -118.342870))
        sleep(5)
        XCUIDevice.shared.location = XCUILocation(location: CLLocation(latitude: 33.935338, longitude: -118.368004))
        sleep(5)
    }
    
    func testTrackingBackground() throws {
        XCUIDevice.shared.location = XCUILocation(location:  CLLocation(latitude: 33.930338, longitude: -118.368004))
        launchApp()
        
        app.tabBars.buttons["Tracking"].tap()
        app.buttons["TrackingButton"].tap()
        sleep(5)
        
        let screenshot1 = XCUIScreen.main.screenshot()
        
        XCUIDevice.shared.press(.home)

        sleep(5)
        XCUIDevice.shared.location = XCUILocation(location: CLLocation(latitude: 33.930338, longitude: -118.368004))
        sleep(5)
        XCUIDevice.shared.location = XCUILocation(location: CLLocation(latitude: 33.933171, longitude: -118.356971))
        sleep(5)
        
        app.launch()
        app.tabBars.buttons["Tracking"].tap()
        let screenshot2 = XCUIScreen.main.screenshot()
        
        XCUIDevice.shared.press(.home)
        allowPermission()
        
        XCTAssertNotEqual(screenshot1.pngRepresentation, screenshot2.pngRepresentation)
    }
}
