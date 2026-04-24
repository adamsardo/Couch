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

        XCTAssertTrue(app.descendants(matching: .any)["privacy-policy-link"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.descendants(matching: .any)["terms-of-use-link"].exists)
        XCTAssertTrue(app.buttons["Continue"].exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
