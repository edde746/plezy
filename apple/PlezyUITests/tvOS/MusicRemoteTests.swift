import XCTest

/// The Siri Remote's Play/Pause where no player owns it: a dev session plays two tracks of the test Plex server
/// (`--dev-music-url`), Now Playing is closed, and on Home each press of Play/Pause pauses the music or plays it again,
/// once per press (the app's probe of what the music published to Now Playing, `music.nowPlaying`).
final class MusicRemoteTests: PlezyUITestCase {
    /// Two tracks of the test Plex server's Sine Album (unclaimed: no token).
    private static let tracks = [
        "http://192.168.0.15:32400/library/parts/121/1793975694/file.flac",
        "http://192.168.0.15:32400/library/parts/122/1793975694/file.flac",
    ]

    func testPlayPauseOffThePlayerTogglesTheMusic() {
        launchDev(arguments: ["--dev-open", "home", "--dev-music-url", Self.tracks.joined(separator: ",")])
        let probe = require("music.nowPlaying", timeout: 60, "the music probe")
        expect(probe, "playing", "the music never played")
        // Playing opens Now Playing on a TV: Menu closes it, the music playing on.
        if element("music.np.screen").exists(within: 10) {
            XCUIRemote.shared.press(.menu)
            if !element("music.np.screen").waitForNonExistence(timeout: 10) { fail("Menu didn't close Now Playing") }
        }
        require("home.screen", timeout: 30, "Home under Now Playing")
        // The music has to keep playing for a while after Now Playing closes, not just at the moment it closes.
        sleep(2)
        expect(probe, "playing", "closing Now Playing stopped the music")
        shot("home music playing")

        XCUIRemote.shared.press(.playPause)
        expect(probe, "paused", "Play/Pause on Home didn't pause the music")
        // One press is one toggle: the music stays paused.
        sleep(2)
        expect(probe, "paused", "one Play/Pause paused the music and played it again")
        shot("home music paused")

        XCUIRemote.shared.press(.playPause)
        expect(probe, "playing", "a second Play/Pause on Home didn't play the music again")
        // The music stays playing: no second toggle follows.
        sleep(2)
        expect(probe, "playing", "one Play/Pause played the music and paused it again")
    }

    /// Now Playing's second row with the remote alone: focus starts on Play/Pause, Down reaches the row under the
    /// transport, where Lyrics, Queue and the sleep timer follow one another. Queue opens the queue's panel with its
    /// Shuffle, Repeat and Clear (each a round button, filled while on) over the tracks; Menu closes it.
    func testDownFromPlayReachesLyricsQueueAndSleep() {
        launchDev(arguments: ["--dev-open", "home", "--dev-music-url", Self.tracks.joined(separator: ",")])
        let probe = require("music.nowPlaying", timeout: 60, "the music probe")
        expect(probe, "playing", "the music never played")
        if !element("music.np.screen").exists(within: 10) {
            // Not opened with the music: the tab bar's Now Playing tab, then its page's button.
            let tab = require("nav.nowPlaying", timeout: 30, "the tab bar's Now Playing")
            for _ in 0..<8 where !focused(tab) {
                XCUIRemote.shared.press(.right)
                _ = waitUntil(0.5) { focused(tab) }
            }
            waitForFocus(tab, "focus reaches the Now Playing tab")
            XCUIRemote.shared.press(.select)
            let open = require("nowPlaying.open", "the Now Playing tab's button")
            for _ in 0..<3 where !focused(open) {
                XCUIRemote.shared.press(.down)
                _ = waitUntil(0.5) { focused(open) }
            }
            XCUIRemote.shared.press(.select)
        }
        require("music.np.screen", timeout: 30, "Now Playing")
        let play = require("music.playPause", "Play/Pause")
        let lyrics = element("music.np.lyrics"), queue = element("music.np.queue"), sleepTimer = element("music.np.sleep")
        waitForFocus(play, "Play/Pause has focus as Now Playing opens")
        XCUIRemote.shared.press(.down)
        let row = [lyrics, queue, sleepTimer]
        _ = waitUntil(3) { row.contains(where: focused) }
        if !row.contains(where: focused) { return fail("Down from Play/Pause reached none of Lyrics, Queue, Sleep timer") }
        for _ in 0..<2 where !focused(lyrics) {
            XCUIRemote.shared.press(.left)
            _ = waitUntil(0.5) { focused(lyrics) }
        }
        waitForFocus(lyrics, "Lyrics leads the row")
        shot("np row lyrics")
        XCUIRemote.shared.press(.right)
        waitForFocus(queue, "Right from Lyrics reaches Queue")
        XCUIRemote.shared.press(.right)
        waitForFocus(sleepTimer, "Right from Queue reaches the sleep timer")
        shot("np row sleep")
        XCUIRemote.shared.press(.left)
        waitForFocus(queue, "Left from the sleep timer reaches Queue")
        XCUIRemote.shared.press(.select)
        for id in ["music.queue.shuffle", "music.queue.repeat", "music.queue.clear", "music.queue.0"] {
            require(id, timeout: 10, "the queue panel's \(id)")
        }
        // The panel's slide-in animation finishes before the screenshot; no element signals its end.
        Thread.sleep(forTimeInterval: 1)
        shot("queue panel")
        XCUIRemote.shared.press(.menu)
        if !element("music.queue.shuffle").waitForNonExistence(timeout: 10) { fail("Menu didn't close the queue panel") }
        require("music.np.screen", "Now Playing under the queue panel")
    }

    /// `element` has focus: itself, or (a menu's button) an element inside it.
    private func focused(_ element: XCUIElement) -> Bool {
        element.hasFocus || element.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).firstMatch.exists
    }

    private func waitForFocus(_ element: XCUIElement, _ what: String) {
        _ = waitUntil(5) { focused(element) }
        if !focused(element) { fail(what) }
    }

    /// Waits until the probe reads `state=<state>`; fails with `what` and the probe's label when it doesn't.
    private func expect(_ probe: XCUIElement, _ state: String, _ what: String) {
        let predicate = NSPredicate(format: "label CONTAINS %@", "state=\(state)")
        if XCTWaiter().wait(for: [expectation(for: predicate, evaluatedWith: probe)], timeout: 30) != .completed {
            fail("\(what): \(probe.label)")
        }
    }
}
