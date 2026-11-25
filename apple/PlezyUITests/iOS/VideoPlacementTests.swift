import UIKit
import XCTest

/// Where the playing video shows, read from the player's probe `player.surface` (`here`, `here external`, `elsewhere`)
/// with the engine's `player.engine`. `PLEZY_MEDIA_URL` (TEST_ENV MEDIA_URL=…) is the video; else Apple's public HLS
/// sample.
final class VideoPlacementTests: PlezyUITestCase {
    private var mediaUrl: String {
        ProcessInfo.processInfo.environment["PLEZY_MEDIA_URL"]
            ?? "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8"
    }

    /// iPad: a second window of the app (`plezy://dev-new-window`) shows the app, while the video and its engine stay
    /// in the window that plays it.
    func testSecondWindowLeavesTheVideoWhereItPlays() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "a second window needs an iPad")
        play()
        let before = position()
        openFromOutside(URL(string: "plezy://dev-new-window")!)
        // The new window opens and draws before the shot; nothing on this side signals it.
        sleep(6)
        shot("two windows")
        let surfaces = app.descendants(matching: .any).matching(identifier: "player.surface").allElementsBoundByIndex
        let labels = surfaces.map(\.label)
        let report = XCTAttachment(string: "surfaces: \(labels)\nengine: \(reading(element("player.engine")))")
        report.name = "placement"
        report.lifetime = .keepAlways
        add(report)
        XCTAssertEqual(labels.filter { $0.hasPrefix("here") }.count, 1, "one window has the video: \(labels)")
        // The position after 3 s more shows the video still advancing.
        sleep(3)
        XCTAssertGreaterThan(position(), before, "the video plays on")
    }

    /// iPhone: with an external screen attached while the video plays (`xcrun simctl io <device> screenConfig
    /// --display=external power on` on the simulator before the run), the video moves there and the controls
    /// stay on the device. Waits up to 150 s for the move. Without an external screen the video plays here.
    func testVideoMovesToTheExternalScreen() throws {
        play()
        let surface = element("player.surface")
        guard let screen = externalScreen else {
            XCTAssertEqual(surface.label, "here", "the video plays on the device")
            throw XCTSkip("no external screen attached")
        }
        if !waitUntil(150, { surface.label == "here external" }) {
            return fail("the video never moved to an external screen: \(surface.label)")
        }
        _ = waitUntil(60) { self.position() >= 3 }
        let playPause = element("player.playPause")
        if !(playPause.exists && playPause.isHittable) { app.windows.firstMatch.tap() }
        _ = waitUntil(5) { playPause.isHittable }
        shot("device with the video on the external screen")
        shot("external screen during playback", of: screen)
    }

    /// iPhone: an external screen attached (as above) gets the app's own black scene while nothing plays, rather than a
    /// mirror of the device: the app's window offers it from the launch on (`display.external`). Waits up to 30 s for
    /// the scene.
    func testExternalScreenGetsTheAppsSceneOutsidePlayback() throws {
        launchDev(arguments: ["--dev-open", "settings", "-probeExternalScreen", "YES"])
        require("settings.row.appearance", timeout: 60, "Settings' Appearance row")
        let probe = require("display.external", "the external screen probe")
        guard let screen = externalScreen else { throw XCTSkip("no external screen attached") }
        let connected = waitUntil(30) { probe.label == "connected" }
        shot("external screen outside playback", of: screen)
        shot("device outside playback", of: XCUIScreen.main)
        if !connected { fail("the external screen has no scene of the app: \(probe.label)") }
    }

    /// The simulator's external screen (TVOut), which draws at scale 1; the iPhone Duo's second screen is its own,
    /// Retina.
    private var externalScreen: XCUIScreen? {
        XCUIScreen.screens.first { $0 != XCUIScreen.main && $0.screenshot().image.scale < 2 }
    }

    private func play() {
        launchDev(arguments: ["--url", mediaUrl])
        let probe = require("player.engine", timeout: 60, "the player's engine probe")
        if !waitUntil(60, { reading(probe).contains("ao=") && !reading(probe).contains("ao=none") }) {
            return fail("the video never started: \(reading(probe))")
        }
    }

    /// The engine's position, from `player.engine`'s `position=<s>`.
    private func position() -> Double {
        let value = reading(element("player.engine"))
        guard let field = value.split(separator: " ").first(where: { $0.hasPrefix("position=") }) else { return -1 }
        return Double(field.dropFirst("position=".count)) ?? -1
    }

    private func reading(_ probe: XCUIElement) -> String {
        probe.label.isEmpty ? (probe.value as? String ?? "") : probe.label
    }
}
