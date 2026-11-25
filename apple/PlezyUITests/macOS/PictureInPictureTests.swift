import XCTest

/// Picture in picture on the Mac: a playing video goes into the system's PiP window from the player's button, and the
/// player shows its placeholder where the video was until the button brings the video back.
/// `PLEZY_MEDIA_URL` (TEST_ENV MEDIA_URL=…) is the video; else Apple's public HLS sample.
final class PictureInPictureTests: PlezyUITestCase {
    private var mediaUrl: String {
        ProcessInfo.processInfo.environment["PLEZY_MEDIA_URL"]
            ?? "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8"
    }

    func testButtonMovesTheVideoIntoPictureInPictureAndBack() {
        launchDev(arguments: ["--url", mediaUrl])
        let window = app.windows.firstMatch
        let pip = element("player.pip")
        // The button is enabled once mpv shows the first frame; moving the pointer brings the controls up.
        let deadline = Date().addingTimeInterval(60)
        while Date() < deadline {
            window.hover()
            if pip.exists, pip.isHittable, pip.isEnabled { break }
            _ = waitUntil(1) { pip.exists && pip.isHittable && pip.isEnabled }
        }
        guard pip.exists, pip.isEnabled else { return fail("picture in picture never became possible") }
        shot("playing")
        pip.click()
        require("player.pipPlaceholder", timeout: 10, "after the PiP button")
        shot("placeholder")
        window.hover()
        if !pip.exists(within: 5) { return fail("no PiP button over the placeholder") }
        pip.click()
        _ = waitUntil(10, every: 0.5) { !element("player.pipPlaceholder").exists }
        if element("player.pipPlaceholder").exists { return fail("the placeholder stayed after leaving PiP") }
        shot("back in the player")
    }
}
