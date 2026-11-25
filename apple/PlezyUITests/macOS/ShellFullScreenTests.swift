import AppKit
import XCTest

/// The shell in a window and in full screen, against the server `PLEZY_DEV_SERVER` names (the default seeded Jellyfin):
/// the sidebar at its default width shows each library's name whole, and in full screen the title bar the pointer brings
/// down at the screen's top edge, over Shows' grid and over a show's detail, leaves the sidebar's rows clear of the
/// window's buttons.
final class ShellFullScreenTests: PlezyUITestCase {
    func testSidebarNamesAndFullScreenTitleBar() throws {
        let server = try XCTUnwrap(
            ProcessInfo.processInfo.environment["PLEZY_DEV_SERVER"].flatMap { $0.isEmpty ? nil : $0 },
            "PLEZY_DEV_SERVER names the server"
        )
        launchDev(arguments: ["--dev-server", server])
        require("home.screen", timeout: 60, "Home")
        let shows = require("nav.library.Shows", timeout: 30, "the sidebar's Shows")
        sleep(2)
        shot("window home")

        let window = app.windows.firstMatch.frame
        pointer(at: CGPoint(x: window.minX + 62, y: window.minY + 16)).click()
        if !waitUntil(10, { self.fullScreen }) { return fail("the green button at Home left the window as it was") }
        sleep(2)
        shot("full screen home", of: XCUIScreen.main)
        let resting = require("nav.home", "the sidebar's Home").frame.minY

        shows.click()
        let card = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'card.'")).firstMatch
        if !card.exists(within: 30) { return fail("Shows lists no card") }
        sleep(1)
        topEdge("grid", resting: resting)
        card.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
        require("detail.screen", timeout: 30, "the show's detail")
        sleep(1)
        topEdge("detail", resting: resting)
        requireWholeNames()

        // The title row's green button (a copy of the title bar's) leaves full screen.
        let full = app.windows.firstMatch.frame
        let green = pointer(at: CGPoint(x: full.minX + 62, y: full.minY + 16))
        green.hover()
        sleep(1)
        green.click()
        if !waitUntil(10, { !self.fullScreen }) { return fail("the title row's green button left the window in full screen") }
        sleep(2)
        requireWholeNames()
    }

    /// The pointer at the screen's top edge brings the menu bar and the title bar (32 points) down under it, and the
    /// screens come down with them: the sidebar's first row stays below the title bar, and goes back up with it.
    private func topEdge(_ name: String, resting: CGFloat) {
        let full = app.windows.firstMatch.frame
        pointer(at: CGPoint(x: full.midX, y: full.minY)).hover()
        sleep(2)
        shot("full screen title bar over the \(name)", of: XCUIScreen.main)
        let home = require("nav.home", "the sidebar's Home")
        XCTAssertGreaterThan(home.frame.minY, full.minY + menuBarHeight + 32, "Home's row clears the title bar over the \(name)")
        pointer(at: CGPoint(x: full.midX, y: full.midY)).hover()
        sleep(2)
        XCTAssertEqual(home.frame.minY, resting, accuracy: 1, "Home's row back in its place after the title bar over the \(name)")
    }

    /// Every library row of the sidebar shows its name in full.
    private func requireWholeNames() {
        let rows = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'nav.library.'"))
        for index in 0..<rows.count {
            let row = rows.element(boundBy: index)
            let name = String(row.identifier.dropFirst("nav.library.".count))
            // A cut name leaves the row narrower than its symbol (some 24 points with its gap) and the name set in the
            // sidebar's font.
            let whole = (name as NSString).size(withAttributes: [.font: NSFont.systemFont(ofSize: NSFont.systemFontSize)]).width
            XCTAssertGreaterThanOrEqual(row.frame.width, 24 + whole, "the sidebar shows \(name) whole")
        }
    }

    /// The menu bar's height on the main screen, which the full-screen title bar comes down under.
    private var menuBarHeight: CGFloat {
        guard let screen = NSScreen.main else { return 0 }
        return screen.frame.maxY - screen.visibleFrame.maxY
    }

    private func pointer(at point: CGPoint) -> XCUICoordinate {
        let window = app.windows.firstMatch
        return window.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: point.x - window.frame.minX, dy: point.y - window.frame.minY))
    }

    /// The window fills its screen, as it does in full screen.
    private var fullScreen: Bool {
        guard let screen = NSScreen.main else { return false }
        let window = app.windows.firstMatch.frame
        return abs(window.width - screen.frame.width) < 2 && abs(window.height - screen.frame.height) < 2
    }
}
