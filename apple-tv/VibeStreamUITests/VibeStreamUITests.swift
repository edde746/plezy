import XCTest

final class VibeStreamUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    // MARK: - Auth Flow Tests

    func testAuthScreenDisplaysPinCode() throws {
        // On fresh launch, auth screen should show
        let signInButton = app.buttons["Sign In with Plex"]
        XCTAssertTrue(signInButton.waitForExistence(timeout: 5))

        // App branding should be visible
        XCTAssertTrue(app.staticTexts["Vibe"].exists)
        XCTAssertTrue(app.staticTexts["Sign in with your Plex account"].exists)
    }

    // MARK: - Navigation Tests

    func testMainTabNavigation() throws {
        // This test requires an authenticated state
        // Skip if not authenticated
        guard app.tabBars.firstMatch.waitForExistence(timeout: 5) else {
            throw XCTSkip("Not authenticated - skipping navigation test")
        }

        // Verify all tabs exist
        XCTAssertTrue(app.tabBars.buttons["Home"].exists)
        XCTAssertTrue(app.tabBars.buttons["Libraries"].exists)
        XCTAssertTrue(app.tabBars.buttons["Search"].exists)
        XCTAssertTrue(app.tabBars.buttons["Downloads"].exists)
        XCTAssertTrue(app.tabBars.buttons["Settings"].exists)
    }

    // MARK: - Search Tests

    func testSearchTabExists() throws {
        guard app.tabBars.firstMatch.waitForExistence(timeout: 5) else {
            throw XCTSkip("Not authenticated")
        }

        XCTAssertTrue(app.tabBars.buttons["Search"].exists)
    }

    // MARK: - Settings Tests

    func testSettingsTabExists() throws {
        guard app.tabBars.firstMatch.waitForExistence(timeout: 5) else {
            throw XCTSkip("Not authenticated")
        }

        XCTAssertTrue(app.tabBars.buttons["Settings"].exists)
    }
}
