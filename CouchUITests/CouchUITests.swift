import XCTest

/// Smoke UI tests for the Couch onboarding entry point. We don't drive the full session
/// because that requires live ElevenLabs / OpenAI credentials.
final class CouchUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testWelcomeScreenShowsPrimaryCTA() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["Practice therapy\nbefore it counts."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Start free practice"].exists)
    }

    @MainActor
    func testOnboardingAdvancesPastSafety() throws {
        let app = XCUIApplication()
        app.launch()
        let startButton = app.buttons["Start free practice"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()
        XCTAssertTrue(app.buttons["Got it"].waitForExistence(timeout: 3))
        app.buttons["Got it"].tap()
        // Quick profile screen now visible
        XCTAssertTrue(app.buttons["Skip for now"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
