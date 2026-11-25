import XCTest

/// The TV's criteria for a run of video formats on the simulated Apple TV with Match Content on (`-simulateMatchContent
/// YES`: each change of the criteria switches the simulated TV's mode for 2 s), through the player's surface as a
/// playback drives it (`-probeDisplayCriteria YES`, the probe `display.criteria`): what is asked of the TV for SDR at
/// 23.976 fps, HDR10 and Dolby Vision profiles 7 and 8, that the surface reports the display ready only once a switch it
/// started has ended, that the same criteria aren't written twice, that turning HDR off during a playback asks for SDR
/// without a reload, and that the playback's end gives the TV its own mode back.
final class DisplayCriteriaTests: PlezyUITestCase {
    func testCriteriaForSdrHdr10AndDolbyVision() throws {
        launchDev(arguments: ["-simulateMatchContent", "YES", "-probeDisplayCriteria", "YES"])
        let probe = require("display.criteria", timeout: 60, "the criteria probe")
        let finished = NSPredicate(format: "value CONTAINS 'done'")
        guard XCTWaiter.wait(for: [expectation(for: finished, evaluatedWith: probe)], timeout: 60) == .completed else {
            return fail("the criteria run didn't finish: \(probe.value as? String ?? "")")
        }
        let text = probe.value as? String ?? ""
        let report = XCTAttachment(string: text)
        report.name = "criteria"
        report.lifetime = .keepAlways
        add(report)
        var steps: [String: (criteria: String, ready: Int, writes: Int)] = [:]
        for line in text.split(separator: "\n").map(String.init) {
            guard let colon = line.firstIndex(of: ":"), let criteria = line.range(of: "criteria="),
                  let ready = line.range(of: " ready=") else { continue }
            let fields = line[ready.upperBound...].split(separator: " ")
            steps[String(line[..<colon])] = (
                String(line[criteria.upperBound..<ready.lowerBound]),
                Int(fields[0]) ?? -1,
                Int(fields.first { $0.hasPrefix("writes=") }?.dropFirst(7) ?? "") ?? -1
            )
        }
        func expect(_ step: String, _ criteria: String, switches: Bool, file: StaticString = #filePath, line: UInt = #line) {
            guard let reading = steps[step] else { return XCTFail("no \(step) in \(text)", file: file, line: line) }
            XCTAssertEqual(reading.criteria, criteria, step, file: file, line: line)
            if switches {
                // 2 s of simulated switch and the 200 ms settle.
                XCTAssertGreaterThanOrEqual(reading.ready, 2_150, "\(step): ready only after the switch", file: file, line: line)
            } else {
                XCTAssertLessThan(reading.ready, 1_000, "\(step): ready at once", file: file, line: line)
            }
        }
        expect("sdr23976", "SDR@23.976 1920x1080 dovi=0.0/-", switches: true)
        expect("hdr10", "HDR10@23.976 3840x2160 dovi=0.0/-", switches: true)
        // Profile 7 is converted to 8.1 (HDR10 base) by the decoder: the TV is asked for that.
        expect("dvP7", "DOLBY_VISION@23.976 3840x2160 dovi=8.6/1", switches: true)
        expect("dvP8", "DOLBY_VISION@23.976 3840x2160 dovi=8.6/-", switches: true)
        expect("dvP8again", "DOLBY_VISION@23.976 3840x2160 dovi=8.6/-", switches: false)
        XCTAssertEqual(steps["dvP8again"]?.writes, steps["dvP8"]?.writes, "the same criteria aren't written again")
        // HDR off during the playback: SDR, the Dolby Vision configuration kept, the format shown again, not reloaded.
        expect("hdrOff", "SDR@23.976 3840x2160 dovi=8.6/-", switches: true)
        XCTAssertTrue(text.contains("done readyWhileSwitching=0 clears=1"), "never ready mid-switch; the end clears: \(text)")
    }
}
