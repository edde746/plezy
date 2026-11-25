import XCTest

/// The Mac's app-wide shortcuts in a `--dev` session signed into the development Jellyfin server (`PLEZY_DEV_SERVER`, or
/// the loopback tunnel to it): ⌘F shows Search with its field
/// focused, ⌘, shows Settings (and again leaves it as it is), and offline ⌘F does nothing.
final class ShellShortcutsTests: PlezyUITestCase {
    private static var server: String {
        let value = ProcessInfo.processInfo.environment["PLEZY_DEV_SERVER"] ?? ""
        // The Mac runs reach the test server through a loopback tunnel: the local network needs a prompt answered.
        return value.isEmpty ? "jellyfin=maestro:maestro@http://127.0.0.1:28096" : value
    }

    func testCommandFShowsSearchWithItsFieldFocused() {
        launchDev(arguments: ["--dev-open", "home", "--dev-server", Self.server])
        require("home.screen", timeout: 60, "the Home screen")
        app.typeKey("f", modifierFlags: .command)
        require("search.field", "Search after ⌘F")
        _ = waitUntil(5, every: 0.2) { keyboardFocus == "search.field" }
        XCTAssertEqual(keyboardFocus, "search.field", "the search field has the keyboard focus after ⌘F")
        shot("search after command f")
    }

    func testCommandCommaShowsSettingsOnce() {
        launchDev(arguments: ["--dev-open", "home", "--dev-server", Self.server])
        require("home.screen", timeout: 60, "the Home screen")
        app.typeKey(",", modifierFlags: .command)
        require("settings.screen", "Settings after ⌘,")
        shot("settings after command comma")
        app.typeKey(",", modifierFlags: .command)
        // Gives the second ⌘, time to act; checked after that Settings stayed.
        Thread.sleep(forTimeInterval: 1)
        XCTAssertTrue(element("settings.screen").exists, "a second ⌘, leaves Settings showing")
        XCTAssertFalse(element("home.screen").exists, "Home stays hidden")
    }

    /// Signed in online first (a fresh session's offline launch has no stored connection to keep), then held offline.
    func testCommandFOfflineDoesNothing() {
        launchDev(arguments: ["--dev-open", "home", "--dev-server", Self.server])
        require("home.screen", timeout: 60, "the Home screen")
        // The server's rows: the sign-in and the profile's bind are done (going offline earlier fails the launch).
        let row = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'hub.'")).firstMatch
        if !row.waitForExistence(timeout: 60) { return XCTFail("Home shows no row from the server after 60 s") }
        changeDevSetting("offline=true")
        require("offline.reconnect", timeout: 30, "the offline chrome's Reconnect")
        app.typeKey("f", modifierFlags: .command)
        // Gives ⌘F time to act; checked after that no Search showed.
        Thread.sleep(forTimeInterval: 2)
        XCTAssertFalse(element("search.field").exists, "no Search offline")
        shot("offline after command f")
    }
}
