#if !os(macOS)
import XCTest

/// What a video's playback hands the system, read through the player's probes: Now Playing (`player.nowPlaying`, what
/// the playback published to `MPNowPlayingInfoCenter`) shows the video with its duration, playing at normal speed once
/// it no longer buffers (the rate is 0 while it does), and a pause as paused; the idle timer (`player.keepAwake`) is off
/// while it plays and on again while it is paused. The video is `PLEZY_PLAY` (`--dev-play`'s `<server>:<item>`,
/// percent-encoded) on `PLEZY_SERVER` (`--dev-server`'s value) when both are set, else `PLEZY_MEDIA_URL` (TEST_ENV
/// MEDIA_URL=…), else Apple's public HLS sample. The Mac's accessibility doesn't report the Now Playing probe's value,
/// and it keeps the display awake by an assertion the probes don't read.
final class NowPlayingTests: PlezyUITestCase {
    private var mediaUrl: String {
        ProcessInfo.processInfo.environment["PLEZY_MEDIA_URL"]
            ?? "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8"
    }

    func testNowPlayingAndIdleTimerFollowThePlayback() {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone { XCUIDevice.shared.orientation = .landscapeLeft }
        #endif
        let env = ProcessInfo.processInfo.environment
        if let server = env["PLEZY_SERVER"], let play = env["PLEZY_PLAY"]?.removingPercentEncoding {
            launchDev(arguments: ["--dev-server", server, "--dev-play", play])
        } else {
            launchDev(arguments: ["--url", mediaUrl])
        }
        let nowPlaying = require("player.nowPlaying", timeout: 60, "the player's Now Playing probe")
        let keepAwake = require("player.keepAwake", timeout: 10, "the player's idle timer probe")
        guard waitUntil(60, { Self.playing(nowPlaying) && Self.duration(nowPlaying) > 0 }) else {
            return fail("Now Playing never showed the video playing at normal speed: \(Self.value(nowPlaying))")
        }
        report("playing", nowPlaying, keepAwake)
        XCTAssertFalse(Self.field("title", nowPlaying).isEmpty, "a title in \(Self.value(nowPlaying))")
        XCTAssertEqual(Self.field("live", nowPlaying), "false", "on demand in \(Self.value(nowPlaying))")
        if !waitUntil(5, { Self.value(keepAwake) == "idleTimerDisabled=true" }) {
            fail("the idle timer stays on while the video plays: \(Self.value(keepAwake))")
        }

        playPause { Self.field("state", nowPlaying) == "paused" }
        if !waitUntil(15, { Self.field("state", nowPlaying) == "paused" && Self.field("rate", nowPlaying) == "0.0" }) {
            fail("Now Playing never showed the pause: \(Self.value(nowPlaying))")
        }
        if !waitUntil(5, { Self.value(keepAwake) == "idleTimerDisabled=false" }) {
            fail("the idle timer stays off while the video is paused: \(Self.value(keepAwake))")
        }
        report("paused", nowPlaying, keepAwake)

        playPause { Self.playing(nowPlaying) }
        if !waitUntil(15, { Self.playing(nowPlaying) }) {
            fail("Now Playing never showed the video playing again at normal speed: \(Self.value(nowPlaying))")
        }
        if !waitUntil(5, { Self.value(keepAwake) == "idleTimerDisabled=true" }) {
            fail("the idle timer stays on once the video plays again: \(Self.value(keepAwake))")
        }
        report("playing again", nowPlaying, keepAwake)
    }

    /// The Small Skip Duration is Now Playing's skip interval and, on iOS, the step the seek buttons name; a change
    /// while the video plays reaches both.
    func testTheSkipIntervalIsTheSmallSkipDuration() {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone { XCUIDevice.shared.orientation = .landscapeLeft }
        #endif
        let env = ProcessInfo.processInfo.environment
        if let server = env["PLEZY_SERVER"], let play = env["PLEZY_PLAY"]?.removingPercentEncoding {
            launchDev(settings: ["seek_time_small=15"], arguments: ["--dev-server", server, "--dev-play", play])
        } else {
            launchDev(settings: ["seek_time_small=15"], arguments: ["--url", mediaUrl])
        }
        let nowPlaying = require("player.nowPlaying", timeout: 60, "the player's Now Playing probe")
        guard waitUntil(60, { Self.playing(nowPlaying) }) else {
            return fail("Now Playing never showed the video playing: \(Self.value(nowPlaying))")
        }
        XCTAssertEqual(Self.field("skipInterval", nowPlaying), "15", "Now Playing's skip interval in \(Self.value(nowPlaying))")
        #if os(iOS)
        assertSeekButtons(say: "15")
        #endif
        changeDevSetting("seek_time_small=20")
        if !waitUntil(15, { Self.field("skipInterval", nowPlaying) == "20" }) {
            fail("Now Playing's skip interval did not follow the setting to 20 s: \(Self.value(nowPlaying))")
        }
        #if os(iOS)
        assertSeekButtons(say: "20")
        #endif
    }

    #if os(iOS)
    /// The seek buttons, the controls raised first, name `seconds` as their step.
    private func assertSeekButtons(say seconds: String) {
        let rewind = element("player.rewind")
        for _ in 0..<3 where !(rewind.exists && rewind.isHittable) {
            element("player.video").tap()
            _ = rewind.exists(within: 3)
        }
        shot("seek buttons \(seconds) s")
        guard rewind.exists else { return fail("the seek buttons never showed") }
        let forward = element("player.fastForward")
        XCTAssertTrue(rewind.label.contains(seconds), "rewind: \(rewind.label)")
        XCTAssertTrue(forward.label.contains(seconds), "fast forward: \(forward.label)")
    }
    #endif

    /// Playing at normal speed: not paused, nor buffering, which Now Playing shows as playing at rate 0.
    private static func playing(_ probe: XCUIElement) -> Bool {
        field("state", probe) == "playing" && field("rate", probe) == "1.0"
    }

    /// The Siri Remote's Play/Pause on Apple TV, with the controls up again once one went unheard (attached as such);
    /// on iOS the controls' play/pause button, the controls raised first.
    private func playPause(until done: () -> Bool) {
        #if os(tvOS)
        XCUIRemote.shared.press(.playPause)
        if waitUntil(6, done) { return }
        let unheard = XCTAttachment(string: "the remote's Play/Pause with the controls down changed nothing in 6 s")
        unheard.name = "unheard play pause"
        unheard.lifetime = .keepAlways
        add(unheard)
        shot("unheard play pause")
        for _ in 0..<3 where !element("player.playPause").exists {
            XCUIRemote.shared.press(.up)
            _ = element("player.playPause").exists(within: 3)
        }
        XCUIRemote.shared.press(.playPause)
        #else
        let button = element("player.playPause")
        for _ in 0..<3 {
            if !(button.exists && button.isHittable) {
                element("player.video").tap()
                _ = button.exists(within: 3)
            }
            if button.exists && button.isHittable {
                button.tap()
                return
            }
        }
        fail("play/pause: not on screen after raising the controls three times")
        #endif
    }

    private func report(_ name: String, _ nowPlaying: XCUIElement, _ keepAwake: XCUIElement) {
        let report = XCTAttachment(string: "\(Self.value(nowPlaying))\n\(Self.value(keepAwake))")
        report.name = name
        report.lifetime = .keepAlways
        add(report)
    }

    private static func value(_ probe: XCUIElement) -> String {
        probe.value as? String ?? ""
    }

    /// The probe's `<name>=<value>` field (`title=…; state=…; rate=…; duration=…; …`).
    private static func field(_ name: String, _ probe: XCUIElement) -> String {
        for part in value(probe).components(separatedBy: "; ") where part.hasPrefix(name + "=") {
            return String(part.dropFirst(name.count + 1))
        }
        return ""
    }

    private static func duration(_ probe: XCUIElement) -> Int {
        Int(field("duration", probe)) ?? 0
    }
}
#endif
