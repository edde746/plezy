import XCTest

/// The player's HDR switch on the Mac: it is an input to the playback's output plan, which writes mpv's
/// `target-colorspace-hint`, read back through the player's probe `player.engine`. Off, the plan stops HDR output
/// (`no`); on again, it lets mpv present HDR (`auto`) where the display shows EDR, and stays at `no` where it doesn't.
/// `PLEZY_HDR_URL` (TEST_ENV HDR_URL=…) is an HDR10 video the Mac reaches (a loopback server: the test build has no
/// local network access); skipped without it.
final class HdrSwitchTests: PlezyUITestCase {
    func testTheSwitchGoesThroughTheOutputPlanToMpv() throws {
        guard let mediaUrl = ProcessInfo.processInfo.environment["PLEZY_HDR_URL"] else {
            throw XCTSkip("PLEZY_HDR_URL names the HDR10 video to play")
        }
        launchDev(arguments: ["--url", mediaUrl])
        require("player.video", timeout: 90, "the player opening \(mediaUrl)")
        let probe = require("player.engine", timeout: 60, "the player's engine probe")
        guard waitUntil(60, { !Self.reading(probe).contains("video=no") }) else { return fail("no video: \(Self.reading(probe))") }
        guard let start = hint(probe, until: { $0 != "none" }) else { return fail("mpv never reported target-colorspace-hint") }
        let hdrDisplay = start == "auto"
        record("before the switch: target-colorspace-hint=\(start), \(hdrDisplay ? "an EDR display" : "no EDR display")")
        toggleHdr()
        guard hint(probe, until: { $0 == "no" }) == "no" else { return fail("the switch off never reached mpv: \(Self.reading(probe))") }
        shot("hdr off")
        toggleHdr()
        let expected = hdrDisplay ? "auto" : "no"
        guard hint(probe, until: { $0 == expected }) == expected else { return fail("the switch on: expected \(expected), \(Self.reading(probe))") }
        shot("hdr on")
    }

    /// Opens the player's options menu and clicks its HDR entry, a switch.
    private func toggleHdr() {
        let options = element("player.more")
        let video = element("player.video")
        let deadline = Date().addingTimeInterval(20)
        while !(options.exists && options.isHittable), Date() < deadline {
            // The pointer has to move over the video: a hover where it already rests is no move.
            video.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.3)).hover()
            video.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).hover()
            _ = waitUntil(0.5) { options.exists && options.isHittable }
        }
        guard options.exists else { return fail("no options button") }
        options.click()
        // A native menu's entry: its title (with its detail on a second line), the identifier not reaching AppKit's item.
        let row = app.menuItems.matching(NSPredicate(format: "title == 'HDR' OR title BEGINSWITH 'HDR\n'")).firstMatch
        if !row.exists(within: 5) { return fail("no HDR switch in the player's options menu") }
        shot("options", of: XCUIScreen.main)
        row.click()
    }

    /// The probe's `target-colorspace-hint` once `done` holds, within 30 s; nil after that.
    private func hint(_ probe: XCUIElement, until done: (String) -> Bool) -> String? {
        var value: String?
        let found = waitUntil(30, every: 0.5) {
            guard let field = Self.reading(probe).split(separator: " ").first(where: { $0.hasPrefix("target-colorspace-hint=") }) else { return false }
            let candidate = String(field.dropFirst("target-colorspace-hint=".count))
            value = candidate
            return done(candidate)
        }
        return found ? value : nil
    }

    private func record(_ text: String) {
        let note = XCTAttachment(string: text)
        note.name = "hdr"
        note.lifetime = .keepAlways
        add(note)
    }

    /// The probe's reading: the Mac's accessibility gives its label.
    private static func reading(_ probe: XCUIElement) -> String {
        probe.label.isEmpty ? (probe.value as? String ?? "") : probe.label
    }
}
