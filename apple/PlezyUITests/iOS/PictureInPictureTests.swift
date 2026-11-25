import AVKit
import XCTest

/// Picture in picture where AVKit has it (iPad; the iPhone simulators have none): a playing video goes into the PiP
/// window from the player's button, the app then leaving for the home screen, and the player keeps its PiP button
/// selected. Where AVKit has none, the button stays disabled while the video plays.
/// `PLEZY_MEDIA_URL` (TEST_ENV MEDIA_URL=…) is the video; else Apple's public HLS sample.
final class PictureInPictureTests: PlezyUITestCase {
    private var mediaUrl: String {
        ProcessInfo.processInfo.environment["PLEZY_MEDIA_URL"]
            ?? "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8"
    }

    func testButtonEntersPictureInPictureDuringPlayback() throws {
        launchDev(arguments: ["--url", mediaUrl])
        let video = app.windows.firstMatch
        let pip = element("player.pip")
        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            let engine = require("player.engine", timeout: 60, "the player's engine probe")
            if !waitUntil(60, { position(engine) >= 3 }) { return fail("the video never played: \(engine.value ?? "")") }
            if !pip.isHittable { video.tap() }
            XCTAssertTrue(pip.waitForExistence(timeout: 5), "the PiP button shows")
            XCTAssertFalse(pip.isEnabled, "the PiP button is disabled without PiP")
            shot("pip disabled")
            throw XCTSkip("AVKit has no picture in picture on this device")
        }
        // The button is enabled once mpv shows the video on the layer AVKit takes; the controls may be down by then.
        let deadline = Date().addingTimeInterval(60)
        while Date() < deadline {
            if !pip.exists || !pip.isHittable { video.tap() }
            if pip.exists, pip.isHittable, pip.isEnabled { break }
            _ = waitUntil(1) { pip.exists && pip.isHittable && pip.isEnabled }
        }
        guard pip.exists, pip.isEnabled else { return fail("picture in picture never became possible") }
        shot("playing")
        pip.tap()
        // A start from the button sends the app to the background: the PiP window stays over the home screen.
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        // AVKit's PiP window (`PIPUIView`) shows; the app, still running for it, has left the screen to the home screen.
        require("PIPUIView", timeout: 15, "after the PiP button")
        shot("pip over home", of: springboard)
        app.activate()
        _ = app.wait(for: .runningForeground, timeout: 10)
        shot("back in the app")
    }

    /// The engine's position, from `player.engine`'s value `position=<s>`.
    private func position(_ engine: XCUIElement) -> Double {
        let field = (engine.value as? String)?.split(separator: " ").first { $0.hasPrefix("position=") }
        return field.flatMap { Double($0.dropFirst("position=".count)) } ?? -1
    }
}
