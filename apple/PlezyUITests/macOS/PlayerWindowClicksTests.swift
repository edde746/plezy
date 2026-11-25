import AppKit
import XCTest

/// The player's top row and the window's buttons take the pointer's clicks, in a window and in full screen, against the
/// server `PLEZY_DEV_SERVER` names (the default seeded Jellyfin): a show's episode played from its detail, Cast opens
/// the device picker, Picture in Picture takes the video into the system's window and back, Back closes the player.
/// In a window the green button puts the window in full screen. In full screen (entered at Home, before the player
/// opens) the title bar the pointer brings down at the screen's top edge takes the click on its green button, and so
/// does the title row's copy of it; each leaves full screen. Each control is hovered a moment before the click, as the
/// pointer reaches it.
final class PlayerWindowClicksTests: PlezyUITestCase {
    private func server() throws -> String {
        try XCTUnwrap(
            ProcessInfo.processInfo.environment["PLEZY_DEV_SERVER"].flatMap { $0.isEmpty ? nil : $0 },
            "PLEZY_DEV_SERVER names the server"
        )
    }

    func testTopButtonsActInAWindow() throws {
        launchDev(arguments: ["--dev-server", try server()])
        require("home.screen", timeout: 60, "Home")
        let window = app.windows.firstMatch.frame
        openEpisode()
        shot("window player")
        castAndPictureInPicture("in a window")
        // The window's green button, by its place: the title bar's buttons aren't in the element tree.
        raiseControls()
        pointerClick(at: CGPoint(x: window.minX + 62, y: window.minY + 16))
        if !waitUntil(10, { self.fullScreen }) { return fail("the green button over the player left the window as it was") }
        // Lets the full screen animation finish before the shot.
        sleep(2)
        shot("window green to full screen")
        app.typeKey("f", modifierFlags: [])
        if !waitUntil(10, { !self.fullScreen }) { return fail("F didn't take the window out of full screen") }
        sleep(2)
        closePlayer("in a window")
    }

    func testTopButtonsActInFullScreen() throws {
        launchDev(arguments: ["--dev-server", try server()])
        require("home.screen", timeout: 60, "Home")
        let window = app.windows.firstMatch.frame
        pointerClick(at: CGPoint(x: window.minX + 62, y: window.minY + 16))
        if !waitUntil(10, { self.fullScreen }) { return fail("the green button at Home left the window as it was") }
        sleep(2)
        openEpisode()
        shot("full screen player")
        castAndPictureInPicture("in full screen")
        // The title bar down from the screen's top edge over the player, and its green button under the menu bar, by
        // its place: AppKit leaves the full-screen title bar's buttons out of the element tree.
        raiseControls()
        let full = app.windows.firstMatch.frame
        pointer(at: CGPoint(x: full.midX, y: full.minY)).hover()
        sleep(2)
        shot("full screen title bar", of: XCUIScreen.main)
        pointerClick(at: CGPoint(x: full.minX + 62, y: full.minY + menuBarHeight + 16))
        if !waitUntil(10, { !self.fullScreen }) { return fail("the title bar's green button left the window in full screen") }
        enterFullScreenAgain()
        // The window's buttons in the title row (copies of the title bar's).
        raiseControls()
        pointerClick(at: CGPoint(x: full.minX + 62, y: full.minY + 16))
        if !waitUntil(10, { !self.fullScreen }) { return fail("the title row's green button left the window in full screen") }
        enterFullScreenAgain()
        closePlayer("in full screen")
    }

    private func enterFullScreenAgain() {
        sleep(2)
        app.typeKey("f", modifierFlags: [])
        if !waitUntil(10, { self.fullScreen }) { return fail("F didn't put the window back in full screen") }
        sleep(2)
    }

    /// The menu bar's height on the main screen, which the full-screen title bar comes down under.
    private var menuBarHeight: CGFloat {
        guard let screen = NSScreen.main else { return 0 }
        return screen.frame.maxY - screen.visibleFrame.maxY
    }

    /// Shows' first show, its Play.
    private func openEpisode() {
        require("nav.library.Shows", timeout: 30, "the sidebar's Shows").click()
        let card = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'card.'")).firstMatch
        if !card.exists(within: 30) { return fail("Shows lists no card") }
        card.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
        require("detail.play", timeout: 30, "the show's Play").click()
        require("player.video", timeout: 60, "the player")
        // The first frame comes; picture in picture waits for it.
        sleep(5)
    }

    private func castAndPictureInPicture(_ mode: String) {
        clickControl("player.cast")
        require("cast.picker", timeout: 5, "Cast \(mode) opens the device picker")
        shot("cast picker \(mode)")
        app.typeKey(.escape, modifierFlags: [])
        if !element("cast.picker").waitForNonExistence(timeout: 5) { return fail("Escape left the device picker up") }

        let pip = element("player.pip")
        if !waitUntil(20, { self.raiseControls(); return pip.exists && pip.isEnabled }) {
            return fail("picture in picture never became possible \(mode)")
        }
        clickControl("player.pip")
        require("player.pipPlaceholder", timeout: 10, "Picture in Picture \(mode) takes the video out")
        shot("picture in picture \(mode)")
        clickControl("player.pip")
        if !element("player.pipPlaceholder").waitForNonExistence(timeout: 10) {
            return fail("Picture in Picture \(mode) didn't bring the video back")
        }
    }

    private func closePlayer(_ mode: String) {
        clickControl("player.back")
        if !element("player.video").waitForNonExistence(timeout: 10) { return fail("Back \(mode) left the player up") }
        require("detail.screen", "the show's detail under the player")
        shot("after back \(mode)")
    }

    /// Brings the controls up, then hovers `id`'s middle a moment and clicks there, as the pointer does.
    private func clickControl(_ id: String) {
        raiseControls()
        let target = require(id, timeout: 5, "the player's \(id)")
        pointerClick(at: CGPoint(x: target.frame.midX, y: target.frame.midY))
    }

    /// The controls come up as the pointer moves over the video.
    private func raiseControls() {
        let video = element("player.video")
        video.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.4)).hover()
        video.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).hover()
    }

    /// The pointer resting a moment at `point` (screen points from the top left), then a click there.
    private func pointerClick(at point: CGPoint) {
        let target = pointer(at: point)
        target.hover()
        Thread.sleep(forTimeInterval: 1)
        target.click()
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
