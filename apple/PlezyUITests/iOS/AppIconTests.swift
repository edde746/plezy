import XCTest

/// Settings › Appearance › App icon on iPhone and iPad: a session with the perks unlocked switches the home-screen icon
/// to an alternate, which the home screen then shows, and back to the default.
final class AppIconTests: PlezyUITestCase {
    func testSwitchesTheHomeScreenIcon() {
        launchDev(arguments: ["--dev-open", "settings"])
        openPicker()
        shot("picker")
        require("appIcon.ember", "the picker's Ember icon").tap()
        confirmIconAlert()
        shot("ember chosen")

        XCUIDevice.shared.press(.home)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        _ = springboard.wait(for: .runningForeground, timeout: 10)
        shot("home screen with ember", of: XCUIScreen.main)

        app.activate()
        require("appIcon.default", "the picker's default icon").tap()
        confirmIconAlert()
        shot("default chosen")
    }

    /// Opens Settings › Appearance, scrolls it to its App icon row and opens the picker.
    private func openPicker() {
        require("settings.row.appearance", timeout: 60, "Settings' Appearance row").tap()
        require("settings.page.appearance", "Appearance")
        let row = require("settings.appIcon", timeout: 20, "Appearance's App icon row")
        for _ in 0..<6 where !row.isHittable { app.swipeUp() }
        row.tap()
        require("appIcon.default", "the picker")
    }

    /// The system's "You have changed the icon" alert after each change, which SpringBoard shows over the app.
    private func confirmIconAlert() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let ok = springboard.buttons["OK"]
        if ok.waitForExistence(timeout: 10) {
            shot("system alert", of: XCUIScreen.main)
            ok.tap()
        } else {
            fail("no alert confirming the icon change")
        }
    }
}
