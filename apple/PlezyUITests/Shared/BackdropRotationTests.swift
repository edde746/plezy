import XCTest

/// A detail's backdrop turning through the item's backgrounds, against the test Jellyfin server
/// (`PLEZY_DEV_SERVER`, else the default one) behind the test's own proxy (`ServerProxy`): every backdrop the server lists
/// becomes three, of which the second answers 404 and the third is the first's picture under another address. Maestro
/// Show's detail, opened from the Shows library, shows its first background, then on the turn (every 10 s) skips the
/// failed second for the third, then comes round to the first again, never showing the second. The backdrop reads the
/// index of the background it shows (`backdrop`, debug builds).
final class BackdropRotationTests: PlezyUITestCase {
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

    func testDetailBackdropTurnsAndSkipsAFailedOne() throws {
        guard let upstream = ServerProxy.upstream(of: Self.server), let proxy = ServerProxy(upstream: upstream) else {
            return fail("no proxy on the loopback in front of \(Self.server)")
        }
        addTeardownBlock {
            let log = XCTAttachment(string: proxy.log)
            log.name = "proxy requests"
            log.lifetime = .keepAlways
            self.add(log)
            proxy.stop()
        }
        try proxy.rewriteJSON(#"BackdropImageTags":\["([^"]+)"\]"#, with: #"BackdropImageTags":["$1","$1-second","$1-third"]"#)
        proxy.respondNotFound(pathContaining: "/Images/Backdrop/1")
        proxy.redirect(pathContaining: "/Images/Backdrop/2", to: "/Images/Backdrop/0")
        launchDev(arguments: ["--dev-server", proxy.server(for: Self.server), "--dev-open", "libraries"])
        require("libraries.screen", timeout: 60, "Libraries")
        let steps = LibrarySteps(test: self)
        steps.pickLibrary("Shows")
        steps.showLibraryTab("browse")
        let show = steps.card(prefix: "Maestro Show")
        if !show.exists(within: 30) { return fail("the Shows library lists no Maestro Show") }
        #if os(tvOS)
        steps.tvFocus([(.left, 4)]) { steps.focusedCard(within: 1)?.label.hasPrefix("Maestro Show") == true }
        XCUIRemote.shared.press(.select)
        #elseif os(macOS)
        show.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
        #else
        show.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        #endif
        let screen = require("detail.screen", timeout: 30, "Maestro Show's detail")
        let backdrop = screen.descendants(matching: .any).matching(identifier: "backdrop").firstMatch
        // The Mac reports a plain element's label, not its value.
        let shown = { backdrop.exists ? (backdrop.label.isEmpty ? backdrop.value as? String ?? "" : backdrop.label) : "" }

        if !waitUntil(30, { shown() == "0" }) { return fail("the first background never shows: \(shown())") }
        shot("first background")
        let turned = readings(of: shown, until: "2", within: 30)
        XCTAssertEqual(turned.last, "2", "the turn skips the failed second background for the third: \(turned)")
        XCTAssertFalse(turned.contains("1"), "the failed second background never shows: \(turned)")
        shot("third background")
        let round = readings(of: shown, until: "0", within: 30)
        XCTAssertEqual(round.last, "0", "the next turn comes round to the first background: \(round)")
        XCTAssertFalse(round.contains("1"), "the failed second background never shows: \(round)")
    }

    /// The readings `read` gives, each change once, until it reads `value` or `timeout` seconds have gone.
    private func readings(of read: () -> String, until value: String, within timeout: TimeInterval) -> [String] {
        var seen: [String] = []
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let reading = read()
            if seen.last != reading { seen.append(reading) }
            if reading == value { break }
            // Samples every reading in turn, so a brief one in between is caught too.
            usleep(250_000)
        }
        return seen
    }
}
