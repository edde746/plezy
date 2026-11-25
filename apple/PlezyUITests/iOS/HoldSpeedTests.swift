import XCTest

/// A finger held on the playing video: 2× while it is held, the speed it had once it lifts, and no loading spinner at
/// either change, read from the player's probes (`player.gestures`, `player.engine`). `PLEZY_MEDIA_URL` (TEST_ENV
/// MEDIA_URL=…) is the video; else Apple's public HLS sample.
final class HoldSpeedTests: PlezyUITestCase {
    private var mediaUrl: String {
        ProcessInfo.processInfo.environment["PLEZY_MEDIA_URL"]
            ?? "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8"
    }

    func testHoldPlaysAtTwiceTheSpeedWithoutASpinner() {
        launchDev(arguments: ["--url", mediaUrl])
        let engine = require("player.engine", timeout: 60, "the player's engine probe")
        let gestures = require("player.gestures", timeout: 10, "the player's gestures probe")
        if !waitUntil(60, { Self.field("position", engine).flatMap(Double.init) ?? 0 >= 3 }) {
            return fail("the video never played: \(Self.reading(engine))")
        }
        // The controls hide while it plays, so the press lands on the video alone.
        _ = waitUntil(10) { !self.element("player.playPause").isHittable }
        shot("playing")
        for hold in 1...2 {
            element("player.video").coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).press(forDuration: 3)
            _ = waitUntil(10) { Self.field("holds", gestures) == String(hold) && Self.field("after", gestures) == "1.00" }
            shot("after hold \(hold)")
            let reading = Self.reading(gestures)
            XCTAssertEqual(Self.field("holds", gestures), String(hold), "the press counts as hold \(hold): \(reading)")
            XCTAssertEqual(Self.field("held", gestures), "2×", "the hold shows 2×: \(reading)")
            XCTAssertEqual(Self.field("heldSpeed", gestures), "2.00", "the video plays at 2× while held: \(reading)")
            XCTAssertEqual(Self.field("after", gestures), "1.00", "the speed is back at 1× once it lifts: \(reading)")
            XCTAssertEqual(Self.field("spinners", gestures), "0", "no loading spinner at the speed changes: \(reading)")
        }
    }

    private static func reading(_ probe: XCUIElement) -> String {
        probe.label.isEmpty ? (probe.value as? String ?? "") : probe.label
    }

    /// `name`'s value in a probe's reading: `name=value`, separated by spaces or `; `.
    private static func field(_ name: String, _ probe: XCUIElement) -> String? {
        reading(probe).split(whereSeparator: { $0 == " " || $0 == ";" })
            .first { $0.hasPrefix("\(name)=") }
            .map { String($0.dropFirst(name.count + 1)) }
    }
}
