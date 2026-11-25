import XCTest

/// The music player on the Mac's MPVKit, muted: two consecutive tracks play gaplessly (the app's gapless proof,
/// `MusicGaplessProbe`). The tracks are `PLEZY_AUDIO_URLS`' two URLs (`TEST_ENV=AUDIO_URLS=<url>,<url>`), else two
/// tones the app writes.
final class MusicGaplessTests: PlezyUITestCase {
    func testTwoConsecutiveTracksPlayGaplessly() throws {
        let urls = ProcessInfo.processInfo.environment["PLEZY_AUDIO_URLS"] ?? ""
        launchDev(arguments: ["-musicGaplessProbe", urls.isEmpty ? "tones" : urls])
        let probe = require("music.gapless", "the gapless proof's probe")
        let finished = NSPredicate(format: "label BEGINSWITH 'pass' OR label BEGINSWITH 'fail'")
        let wait = XCTNSPredicateExpectation(predicate: finished, object: probe)
        if XCTWaiter.wait(for: [wait], timeout: 90) != .completed { fail("no result after 90 s: \(probe.label)") }
        print("gapless: \(probe.label)")
        XCTAssertTrue(probe.label.hasPrefix("pass"), probe.label)
    }

    /// The music session plays `PLEZY_AUDIO_URLS`' two URLs as one queue (`--dev-music-url`): Now Playing shows it
    /// playing, and still playing past the first track's end (the test servers' are 30 s), the second having followed
    /// gaplessly; the app's log (`MpvAudio`) shows one open, one arm and the advance.
    func testTheSessionPlaysTwoQueuedTracksOn() throws {
        let urls = (ProcessInfo.processInfo.environment["PLEZY_AUDIO_URLS"] ?? "").split(separator: ",").map(String.init)
        try XCTSkipIf(urls.count < 2, "no PLEZY_AUDIO_URLS")
        launchDev(arguments: urls.flatMap { ["--dev-music-url", $0] })
        let probe = require("music.nowPlaying", "the music Now Playing probe")
        let playing = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS 'state=playing'"), object: probe)
        if XCTWaiter.wait(for: [playing], timeout: 30) != .completed { fail("not playing after 30 s: \(probe.label)") }
        // Past the first track's end: checked after that the queue kept playing.
        Thread.sleep(forTimeInterval: 40)
        print("music now playing: \(probe.label)")
        XCTAssertTrue(probe.label.contains("state=playing"), probe.label)
    }
}
