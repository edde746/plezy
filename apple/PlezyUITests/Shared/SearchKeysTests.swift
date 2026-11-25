import XCTest

/// Keys in Search's field on the Mac (the system's keyboard navigation on, so Tab and the arrows reach every control),
/// against the development Jellyfin server (`PLEZY_DEV_SERVER`, else the default): Escape empties a field holding text and
/// keeps focus in it; Return in the field submits the search, its focus landing on the first result without opening it,
/// and Return there opens it. Apple TV's field is the system's (`searchable`), its keys the system's.
final class SearchKeysTests: PlezyUITestCase {
    private static let query = "Maestro Show"

    private static var server: String {
        let value = ProcessInfo.processInfo.environment["PLEZY_DEV_SERVER"] ?? ""
        guard value.isEmpty else { return value }
        #if os(macOS)
        // The Mac runs reach the test server through a loopback tunnel: the local network needs a prompt answered.
        return "jellyfin=maestro:maestro@http://127.0.0.1:28096"
        #else
        return "jellyfin=maestro:maestro@http://192.168.0.15:28096"
        #endif
    }

    #if os(macOS)
    func testFieldBackAndDown() throws {
        try requireKeyboardNavigation()
        launchDev(arguments: ["--dev-open", "search", "--dev-server", Self.server])
        require("search.screen", timeout: 90, "the Search screen")
        let field = require("search.field", "the search field")
        type(Self.query, into: field)
        let result = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'search.result.'")).firstMatch
        if !result.exists(within: 30) { fail("typing \(Self.query) lists nothing") }
        Thread.sleep(forTimeInterval: 2)
        shot("search results")

        focusField()

        press(back)
        if text(of: field).contains(Self.query) { fail("Back left '\(text(of: field))' in the field") }
        if keyboardFocus != "search.field" { fail("Back in the field holding text moved focus to \(keyboardFocus)") }
        shot("search back cleared")
    }

    func testReturnSubmitsThenOpensTheResult() throws {
        try requireKeyboardNavigation()
        launchDev(arguments: ["--dev-open", "search", "--dev-server", Self.server])
        require("search.screen", timeout: 90, "the Search screen")
        let field = require("search.field", "the search field")
        field.click()
        field.typeText(Self.query + "\n")
        if !waitUntil(30, { self.keyboardFocus.hasPrefix("search.result.") }) {
            return fail("Return in the field landed focus on \(keyboardFocus), not the first result")
        }
        if element("detail.screen").exists(within: 2) { return fail("Return in the field also opened the result") }
        if text(of: field) != Self.query { fail("the field holds '\(text(of: field))' after Return") }
        app.typeKey(.return, modifierFlags: [])
        require("detail.screen", timeout: 20, "Return on the focused result opens it")
    }
    #endif

    // MARK: - Steps

    #if os(macOS)
    private let back = XCUIKeyboardKey.escape

    private func press(_ key: XCUIKeyboardKey) {
        app.typeKey(key, modifierFlags: [])
        Thread.sleep(forTimeInterval: 0.8)
    }

    private func type(_ text: String, into field: XCUIElement) {
        field.click()
        field.typeText(text)
    }

    private func focusField() {
        element("search.field").click()
        Thread.sleep(forTimeInterval: 1)
    }
    #endif

    private func text(of field: XCUIElement) -> String {
        let value = (field.value as? String) ?? ""
        return value == field.placeholderValue ? "" : value
    }
}
