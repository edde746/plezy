import XCTest

/// The TV's criteria for real files played by the player on the simulated Apple TV with Match Content on
/// (`-simulateMatchContent YES`), read from the player's probe `player.display`: mpv's decoded format through the
/// shared `AppleDisplayCriteria` to `AVDisplayManager`. The files come from the run's environment, each a plain http URL
/// the player opens (`--url`): `PLEZY_SDR_URL` (H.264 SDR 1080p at 23.976 fps), `PLEZY_HDR10_URL` (HEVC HDR10 2160p),
/// `PLEZY_DV81_URL` (Dolby Vision profile 8.1, level 6) and `PLEZY_DV5_URL` (profile 5, level 6); a test whose URL
/// isn't given is skipped.
final class DisplayCriteriaPlaybackTests: PlezyUITestCase {
    func testSdr23976() throws { try play("SDR_URL", expect: "SDR@23.976 1920x1080 dovi=0.0/-") }

    func testHdr10() throws { try play("HDR10_URL", expect: "HDR10@23.976 3840x2160 dovi=0.0/-") }

    func testDolbyVisionProfile81() throws { try play("DV81_URL", expect: "DOLBY_VISION@23.976 3840x2160 dovi=8.6/-") }

    func testDolbyVisionProfile5() throws { try play("DV5_URL", expect: "DOLBY_VISION@23.976 3840x2160 dovi=5.6/-") }

    /// Plays the file in `PLEZY_<variable>` and checks the criteria the TV was asked for, and that the player started
    /// it only once the simulated mode switch had ended.
    private func play(_ variable: String, expect criteria: String) throws {
        let url = ProcessInfo.processInfo.environment["PLEZY_\(variable)"] ?? ""
        try XCTSkipIf(url.isEmpty, "no PLEZY_\(variable)")
        launchDev(arguments: ["--url", url, "-simulateMatchContent", "YES"])
        let probe = require("player.display", timeout: 60, "the player's display probe")
        let written = NSPredicate(format: "value CONTAINS 'criteria=' AND NOT (value CONTAINS 'criteria=none')")
        guard XCTWaiter.wait(for: [expectation(for: written, evaluatedWith: probe)], timeout: 60) == .completed else {
            return fail("no criteria written: \(probe.value as? String ?? "")")
        }
        // The file starts once the switch (2 s) and the settle have passed.
        let engine = element("player.engine")
        Thread.sleep(forTimeInterval: 3)
        let value = probe.value as? String ?? ""
        let report = XCTAttachment(string: "\(value)\n\(engine.value as? String ?? "")")
        report.name = "display \(variable)"
        report.lifetime = .keepAlways
        add(report)
        shot(variable)
        XCTAssertTrue(value.hasSuffix("criteria=\(criteria)"), value)
        XCTAssertTrue(value.contains("readyWhileSwitching=0"), "the file started during the switch: \(value)")
    }
}
