import XCTest

/// Show profile link: a `--dev` session signed in to the test server (`--dev-server`, its local profile "Dev"),
/// Settings → Manage profiles, the tile's context menu (a long press, a right click on the Mac, a long press of Select
/// on Apple TV), Show profile link: the link sheet (`picker.link`) with its code, the link and what opening it does.
final class ProfileLinkTests: PlezyUITestCase {
    #if os(macOS)
    // The Mac runs reach the test servers through loopback tunnels.
    private nonisolated static let host = "127.0.0.1"
    #else
    private nonisolated static let host = "192.168.0.15"
    #endif

    private static var server: String {
        let value = ProcessInfo.processInfo.environment["PLEZY_DEV_SERVER"] ?? ""
        return value.isEmpty ? "jellyfin=maestro:maestro@http://\(host):28096" : value
    }

    func testShowProfileLink() {
        launchDev(arguments: ["--dev-server", Self.server, "--dev-open", "settings"])
        // The hub fills in as the session loads, rows coming in above Manage profiles: the server's Account preferences
        // comes last; a click while rows move goes nowhere.
        require("settings.row.account_preferences", timeout: 30, "Settings' Account preferences row")
        activate("settings.row.profiles", "Settings → Manage profiles")
        let tile = require("picker.tile.0", timeout: 20, "the picker's profile")
        #if os(tvOS)
        _ = tile
        walkFocus(to: "picker.tile.0", "the picker's profile")
        XCUIRemote.shared.press(.select, forDuration: 1.5)
        #elseif os(macOS)
        tile.rightClick()
        #else
        tile.press(forDuration: 1.2)
        #endif
        // A menu item reads its words as its title on the Mac, as its label elsewhere.
        let entry = app.descendants(matching: .any).matching(NSPredicate(
            format: "identifier BEGINSWITH 'picker.tile.0.menu.' AND (label == 'Show profile link' OR title == 'Show profile link')"
        )).firstMatch
        if !entry.exists(within: 10) { fail("no Show profile link in the profile's context menu") }
        #if os(tvOS)
        // The context menu's focus starts on its first entry, Show profile link (Manage is the button under the tile).
        press(.select)
        #else
        activate(entry.identifier, "Show profile link")
        #endif
        require("picker.link", timeout: 10, "the profile's link sheet")
        require("picker.link.qr", timeout: 10, "the link's QR code")
        let text = require("picker.link.text", "the link as text")
        // A selectable text reads as its value on the Mac, as its label elsewhere.
        let link = text.label.isEmpty ? ((text.value as? String) ?? "") : text.label
        if !link.hasPrefix("plezy://") { fail("the sheet's link is '\(link)', not a plezy:// link") }
        let hint = app.staticTexts["Opening this link switches to this profile."]
        if !hint.exists(within: 5) { fail("the sheet doesn't say what opening the link does") }
        shot("profile link")
    }

    /// Presses `id` as each platform does: a tap, a click, or the remote's focus walked there and Select.
    private func activate(_ id: String, _ what: String) {
        let target = require(id, what)
        #if os(tvOS)
        _ = target
        walkFocus(to: id, what)
        press(.select)
        #elseif os(macOS)
        if !waitUntil(10, { target.isHittable }) { fail("\(what): \(id) can't be clicked") }
        target.click()
        #else
        if !waitUntil(10, { target.isHittable }) { fail("\(what): \(id) can't be tapped") }
        target.tap()
        #endif
    }

    #if os(tvOS)
    /// The element that has focus.
    private var focused: XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).firstMatch
    }

    private var focusedId: String? { (try? focused.snapshot())?.identifier }

    /// Whether `id` has focus: the element itself, or the anonymous list cell around it (a settings row). Not another
    /// named element around it.
    private func holdsFocus(_ id: String) -> Bool {
        guard let target = try? element(id).snapshot() else { return false }
        if target.hasFocus { return true }
        guard let here = try? focused.snapshot(), here.identifier.isEmpty else { return false }
        return here.frame.insetBy(dx: -4, dy: -4).contains(target.frame) && here.frame.height < app.frame.height / 2
    }

    /// Presses the remote's `button`, then waits for the focus engine to settle (the focused frame read the same twice).
    private func press(_ button: XCUIRemote.Button) {
        XCUIRemote.shared.press(button)
        var last: CGRect??
        _ = waitUntil(3) {
            let frame = (try? focused.snapshot())?.frame
            defer { last = .some(frame) }
            return last == .some(frame)
        }
    }

    /// Presses the arrow towards `id` from the focused element, frame to frame, until `id` has focus.
    private func walkFocus(to id: String, limit: Int = 12, _ what: String) {
        let target = require(id, what)
        for _ in 0..<limit {
            if holdsFocus(id) { return }
            let here = focused
            if !here.exists(within: 5) { return fail("\(what): nothing has focus") }
            press(Self.direction(from: here.frame, to: target.frame))
        }
        if !waitUntil(2, { holdsFocus(id) }) { fail("\(what): \(limit) presses left focus on \(focusedId ?? "nothing"), not \(id)") }
    }

    /// The arrow from frame `here` towards frame `there`: sideways when they share a row, else up or down. Frames that
    /// overlap by a few points share no row or column: a menu's rows overlap their neighbours by a fraction of one.
    private static func direction(from here: CGRect, to there: CGRect) -> XCUIRemote.Button {
        let columnsOverlap = min(here.maxX, there.maxX) - max(here.minX, there.minX) > 4
        let rowsOverlap = min(here.maxY, there.maxY) - max(here.minY, there.minY) > 4
        let across = there.midX - here.midX
        let down = there.midY - here.midY
        if rowsOverlap || (!columnsOverlap && abs(across) > abs(down)) { return across > 0 ? .right : .left }
        return down > 0 ? .down : .up
    }
    #endif
}
