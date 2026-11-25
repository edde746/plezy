import XCTest

/// The music session in the system's Now Playing on iPhone: a dev session plays two tracks of the test Plex server
/// (`--dev-music-url`), and Now Playing shows the first as audio playing at normal speed, with next as its transport
/// (previous is off: nothing comes before the first track) and no skip buttons (the app's probe of what it published,
/// `music.nowPlaying`), and in Control Center and the cover sheet (screenshots).
final class MusicControlsTests: PlezyUITestCase {
    /// Two tracks of the test Plex server's Sine Album (unclaimed: no token).
    private static let tracks = [
        "http://192.168.0.15:32400/library/parts/121/1793975694/file.flac",
        "http://192.168.0.15:32400/library/parts/122/1793975694/file.flac",
    ]

    func testMusicShowsInNowPlaying() {
        launchDev(arguments: ["--dev-music-url", Self.tracks.joined(separator: ",")])
        let probe = require("music.nowPlaying", timeout: 60, "the music probe")
        let playing = NSPredicate(format: "label CONTAINS 'state=playing'")
        if XCTWaiter().wait(for: [expectation(for: playing, evaluatedWith: probe)], timeout: 60) != .completed {
            fail("Now Playing never showed the music playing: \(probe.label)")
        }
        let published = probe.label
        for expected in ["title=file.flac", "rate=1.0", "live=false", "next=true", "previous=false", "skip=false"] {
            XCTAssertTrue(published.contains(expected), "\(expected) in \(published)")
        }
        shot("app")

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        // Control Center: a swipe down from the top right corner.
        swipeDown(springboard, fromX: 0.95)
        shot("control center", of: XCUIScreen.main)
        swipeUp(springboard)
        // The cover sheet (the lock screen's notifications and Now Playing): a swipe down from the top left.
        swipeDown(springboard, fromX: 0.1)
        shot("cover sheet", of: XCUIScreen.main)
        swipeUp(springboard)
    }

    private func swipeDown(_ springboard: XCUIApplication, fromX x: CGFloat) {
        let start = springboard.coordinate(withNormalizedOffset: CGVector(dx: x, dy: 0.002))
        start.press(forDuration: 0.1, thenDragTo: springboard.coordinate(withNormalizedOffset: CGVector(dx: x, dy: 0.7)))
        // System UI slides in and loads artwork before the screenshot; nothing in the app signals it.
        sleep(4)
    }

    private func swipeUp(_ springboard: XCUIApplication) {
        let start = springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.995))
        start.press(forDuration: 0.1, thenDragTo: springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3)))
        // The system sheet's dismiss animation finishes before the next swipe.
        sleep(1)
    }
}
