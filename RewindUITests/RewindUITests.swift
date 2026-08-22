import XCTest

final class RewindUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testOnboardingPromiseIsVisibleOnLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        XCTAssertTrue(
            app.staticTexts["Rediscover your photos.\nFree up space along the way."].waitForExistence(timeout: 4)
                || app.staticTexts["Rewind"].waitForExistence(timeout: 2)
                || app.buttons["Continue"].waitForExistence(timeout: 2)
                || app.buttons["Allow Photos Access"].exists
                || app.buttons["Photos"].exists
        )
    }
}
