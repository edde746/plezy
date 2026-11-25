#if os(iOS)
import XCTest

/// Watch Together's prompts as a guest of another app's room: the session joins `PLEZY_WATCH_ROOM` (`--dev-watch-room`)
/// on the relay `PLEZY_WATCH_RELAY`, signed in with `PLEZY_DEV_SERVER`, while the other participant (a scripted
/// witness) hosts it and shares Two Versions as 52 s, then, once this user plays a copy, Maestro Movie as 42 s; the
/// server's copies are 40 s and 30 s, so each asks first. Skipped without them.
///
/// The screen's Now Playing card asks (Play Anyway, Choose Another Copy, Don't Play); Choose Another Copy opens the
/// copies page, and the copy picked there plays once the room took it (the page closes, the player opens). The second
/// share opens the player's own prompt, Play Anyway answers it. Then, while the relay is down, the player shows
/// "Reconnecting..." over the video.
final class WatchShotsTests: PlezyUITestCase {
    func testGuestPromptsAndReconnecting() throws {
        let env = ProcessInfo.processInfo.environment
        func value(_ name: String) -> String? { env[name].flatMap { $0.isEmpty ? nil : $0 } }
        guard let code = value("PLEZY_WATCH_ROOM"), let relay = value("PLEZY_WATCH_RELAY"), let server = value("PLEZY_DEV_SERVER") else {
            throw XCTSkip("needs PLEZY_WATCH_ROOM, PLEZY_WATCH_RELAY and PLEZY_DEV_SERVER")
        }
        launchDev(settings: ["watch_party_relay_url=\(relay)"], arguments: ["--dev-server", server, "--dev-watch-room", code])
        require("watch.code", timeout: 60, "the room's code")

        // The screen's card asks about the room's video.
        let choose = element("watch.mismatchChoose")
        for _ in 0..<6 where !(choose.exists(within: 5) && choose.isHittable) {
            element("watch.screen").swipeUp(velocity: .slow)
        }
        if !choose.exists { fail("the screen's mismatch block: no watch.mismatchChoose") }
        // Lets the swipes' momentum settle before the screenshot: nothing signals its end.
        sleep(1)
        shot("room-mismatch")

        choose.tap()
        let candidate = require("watch.candidate.0", timeout: 15, "the copies page's first copy")
        _ = waitUntil(5) { candidate.isHittable }
        shot("copies")
        candidate.tap()
        // The room takes the copy: the page closes and the player opens on it.
        XCTAssertTrue(candidate.waitForNonExistence(timeout: 30), "the copies page closes once the room took the copy")
        require("player.video", timeout: 60, "the player opening on the copy")
        // The video's first frames draw before the screenshot; nothing signals them.
        sleep(3)
        shot("player")

        // The second share: the player's own prompt opens by itself.
        let sheet = require("watch.mismatch", timeout: 120, "the player's mismatch prompt")
        _ = waitUntil(5) {
            self.app.descendants(matching: .any).matching(identifier: "watch.playAnyway").allElementsBoundByIndex.contains { $0.isHittable }
        }
        shot("player-mismatch")
        // The prompt's own button, the one on screen: the Watch Together screen under the player has one of its name.
        let buttons = app.descendants(matching: .any).matching(identifier: "watch.playAnyway").allElementsBoundByIndex
        guard let play = buttons.first(where: { $0.isHittable }) else { fail("the prompt's Play Anyway: none of \(buttons.count) on screen"); return }
        play.tap()
        XCTAssertTrue(sheet.waitForNonExistence(timeout: 20), "Play Anyway closes the prompt")
        // Lets playback run a while after Play Anyway before the screenshot.
        sleep(3)
        shot("play-anyway")

        // The relay goes down for a while: the pill shows, then goes with the room's end or its return.
        let pill = element("player.watch.reconnecting")
        if !pill.exists(within: 120) { fail("no reconnecting pill while the relay is down") }
        shot("reconnecting")
        // A second screenshot of the pill a while later: the period is what it shows.
        sleep(3)
        shot("reconnecting-2")
        // Waits out the relay's downtime before the last screenshot.
        sleep(30)
        shot("after-relay")
    }
}
#endif
