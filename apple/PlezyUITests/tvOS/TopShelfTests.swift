import XCTest

/// The Top Shelf's payload from a server's Continue Watching on Apple TV: a `--dev` session signs into the server
/// `PLEZY_DEV_SERVER` names (`--dev-server`'s `<kind>=<user>:<password>@<url>`, its local profile "Dev"), the app
/// publishes the profile's Continue Watching with its posters to the App Group, and the extension's reading of it
/// (`app.topShelf`, the `TopShelfProbe` over `TopShelfContent`, the code the extension runs, here in the app's process)
/// shows an owner, items and their posters as files on disk, none as a remote URL. The extension itself and the system's
/// shelf are not driven: the Home button's screenshot is for the eye only.
final class TopShelfTests: PlezyUITestCase {
    func testContinueWatchingPayloadHasLocalPosters() throws {
        launchDev(arguments: ["--dev-server", try server()])
        requireShelf()
        XCTAssertTrue(element("app.topShelf").label.hasSuffix(" remote=0"), "every poster is a file: \(element("app.topShelf").label)")
        shot("app")
        XCUIRemote.shared.press(.home)
        // Lets the system's home screen come in before the shot, which is for the eye only.
        sleep(4)
        shot("home", of: XCUIScreen.main)
    }

    /// Deleting the active profile ends its session: the shelf's payload has no owner and no item within a few seconds,
    /// and nothing the profile's write had under way brings its shelf back.
    func testRemovingTheProfileClearsTheShelf() throws {
        launchDev(arguments: ["--dev-server", try server(), "--dev-open", "settings"])
        requireShelf()
        require("settings.row.manage_libraries", timeout: 60, "Settings once the launch's sign-in has ended")
        activate("settings.row.profiles", limit: 40, "Settings → Profiles")
        require("picker.tile.0", timeout: 20, "the picker's profile")
        activate("picker.tile.0.manage", "the profile's Manage")
        activate("profile.delete", limit: 40, "Delete profile")
        require("confirm.ok", timeout: 10, "Delete profile asks first")
        activate("confirm.ok", "Delete")
        let probe = element("app.topShelf")
        let cleared = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in probe.label.hasPrefix("owner=no items=0 ") }, object: nil)
        if XCTWaiter().wait(for: [cleared], timeout: 6) != .completed {
            fail("the Top Shelf still shows the deleted profile's shelf: \(probe.exists ? probe.label : "no probe")")
        }
        shot("cleared")
        // A write the profile had under way would land within its 8 s of downloads.
        sleep(10)
        if !probe.label.hasPrefix("owner=no items=0 ") { fail("the deleted profile's shelf came back: \(probe.label)") }
    }

    private func server() throws -> String {
        guard let server = ProcessInfo.processInfo.environment["PLEZY_DEV_SERVER"] else { throw XCTSkip("needs PLEZY_DEV_SERVER") }
        return server
    }

    /// Waits for the profile's shelf: an owner, an item and a poster on disk.
    private func requireShelf() {
        let probe = element("app.topShelf")
        let shown = NSPredicate { _, _ in
            let label = probe.label
            return label.hasPrefix("owner=yes") && !label.contains(" shelf=0 ") && !label.contains(" images=0 ")
        }
        let wait = XCTNSPredicateExpectation(predicate: shown, object: nil)
        if XCTWaiter().wait(for: [wait], timeout: 90) != .completed {
            fail("the Top Shelf shows no item with a poster: \(probe.exists ? probe.label : "no probe")")
        }
    }

    /// The element that has focus.
    private var focused: XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).firstMatch
    }

    /// Whether `id` has focus: the element itself, or the anonymous list cell around it (a settings row).
    private func holdsFocus(_ id: String) -> Bool {
        guard let target = try? element(id).snapshot() else { return false }
        if target.hasFocus { return true }
        guard let here = try? focused.snapshot(), here.identifier.isEmpty else { return false }
        return here.frame.insetBy(dx: -4, dy: -4).contains(target.frame) && here.frame.height < app.frame.height / 2
    }

    /// Walks the remote's focus to `id`, frame to frame, and presses Select.
    private func activate(_ id: String, limit: Int = 12, _ what: String) {
        let target = require(id, what)
        for _ in 0..<limit where !holdsFocus(id) {
            let here = focused
            if !here.exists(within: 5) { return fail("\(what): nothing has focus") }
            press(Self.direction(from: here.frame, to: target.frame))
        }
        if !holdsFocus(id) { return fail("\(what): \(limit) presses didn't reach \(id)") }
        press(.select)
    }

    /// Presses the remote's `button`, then waits for the focus engine to settle (the focused frame read the same twice).
    private func press(_ button: XCUIRemote.Button) {
        XCUIRemote.shared.press(button)
        var last: CGRect??
        let deadline = Date().addingTimeInterval(3)
        while Date() < deadline {
            let frame = (try? focused.snapshot())?.frame
            if last == .some(frame) { return }
            last = .some(frame)
            Thread.sleep(forTimeInterval: 0.25)
        }
    }

    /// The arrow from frame `here` towards frame `there`: sideways when they share a row, else up or down (a row's
    /// trailing button reaches the next row down, not the row's start).
    private static func direction(from here: CGRect, to there: CGRect) -> XCUIRemote.Button {
        let rowsOverlap = min(here.maxY, there.maxY) - max(here.minY, there.minY) > 4
        if rowsOverlap { return there.midX > here.midX ? .right : .left }
        return there.midY > here.midY ? .down : .up
    }
}
