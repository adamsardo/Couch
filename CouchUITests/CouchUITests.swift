import XCTest

/// Smoke UI tests for the Couch onboarding entry point. We don't drive the full session
/// because that requires live ElevenLabs / OpenAI credentials.
final class CouchUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testNameScreenShowsPrimaryCTA() throws {
        let app = launchApp()
        XCTAssertTrue(app.staticTexts["What's your name?"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Continue"].exists)
    }

    @MainActor
    func testOnboardingAdvancesPastName() throws {
        let app = launchApp()

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
    func testPracticeLauncherOpensSessionIntro() throws {
        let app = launchApp(onboarded: true)

        let runRep = app.buttons["Run rep with Marcus"]
        XCTAssertTrue(runRep.waitForExistence(timeout: 5))
        runRep.tap()

        XCTAssertTrue(app.staticTexts["Warm-up with Marcus"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Start the rep"].exists)
        XCTAssertTrue(app.staticTexts["Virtual patient. Practice, not therapy."].exists)

        let backButton = app.buttons["Back"]
        XCTAssertTrue(backButton.waitForExistence(timeout: 3))
        backButton.tap()
        XCTAssertTrue(app.buttons["Run rep with Marcus"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testSettingsShowsLegalLinks() throws {
        let app = launchApp(onboarded: true)

        let settings = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 5))
        settings.tap()

        XCTAssertTrue(app.staticTexts["Privacy and terms"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Privacy Policy"].exists)
        XCTAssertTrue(app.buttons["Terms of Use"].exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            _ = launchApp()
        }
    }

    @MainActor
    private func launchApp(onboarded: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = onboarded
            ? ["-CouchUITest", "-CouchUITestOnboarded"]
            : ["-CouchUITest"]
        app.launch()
        return app
    }
}
