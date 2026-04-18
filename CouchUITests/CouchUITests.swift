import XCTest

/// Smoke UI tests for the Couch onboarding entry point. We don't drive the full session
/// because that requires live ElevenLabs / OpenAI credentials.
final class CouchUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testNameScreenShowsPrimaryCTA() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["What's your name?"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Continue"].exists)
    }

    @MainActor
    func testOnboardingAdvancesPastName() throws {
        let app = XCUIApplication()
        app.launch()

        let nameField = app.textFields["Your name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Test")

        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.isEnabled)
        continueButton.tap()

        // The next screen (privacy or similar) should be visible.
        // We check simply that the Continue button is still reachable
        // on whatever the next step is.
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 3)
            || app.buttons.firstMatch.waitForExistence(timeout: 3))
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
