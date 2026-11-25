import XCTest

/// The Mac's refresh-rate switch (`-probeDisplayModes YES`, the probe `display.modes`): the refresh-rate variants of the
/// display's current mode, the shared policy's pick for common frame rates, the switch to the first pick and the
/// restore. Once on the simulated MacBook Pro display (`-simulateDisplayModes YES`, ProMotion with fixed 60, 59.94, 50,
/// 48 and 47.95 Hz), whose picks are known, and once on the Mac's real display, as far as it offers rates.
final class DisplayModesTests: PlezyUITestCase {
    func testSimulatedDisplayPicksSwitchesAndRestores() {
        let lines = runProbe(["-simulateDisplayModes", "YES"])
        XCTAssertEqual(lines.first, "modes=120.000,60.000,59.940,50.000,48.000,47.950 current=120.000")
        // The smallest multiple within 0.5 %: 23.976 fps at 47.95 Hz (×2), not ProMotion's 120 Hz (×5).
        XCTAssertTrue(lines.contains("pick 23.976=47.950"), "\(lines)")
        XCTAssertTrue(lines.contains("pick 24.000=48.000"), "\(lines)")
        XCTAssertTrue(lines.contains("pick 25.000=50.000"), "\(lines)")
        XCTAssertTrue(lines.contains("pick 29.970=59.940"), "\(lines)")
        XCTAssertTrue(lines.contains("pick 50.000=50.000"), "\(lines)")
        XCTAssertTrue(lines.contains("pick 59.940=59.940"), "\(lines)")
        XCTAssertTrue(lines.contains("switch 47.950 switched=true now=47.950"), "\(lines)")
        XCTAssertTrue(lines.contains("restored now=120.000"), "\(lines)")
    }

    func testRealDisplaySwitchesToThePickAndRestores() {
        let lines = runProbe([])
        guard let first = lines.first, first.hasPrefix("modes=") else { return XCTFail("no modes: \(lines)") }
        let current = String(first[first.range(of: "current=")!.upperBound...])
        guard let switchLine = lines.first(where: { $0.hasPrefix("switch ") }) else { return XCTFail("no switch line: \(lines)") }
        if switchLine == "switch none" {
            // A display with one rate at its resolution, or none that fits a frame rate better: nothing to switch.
            XCTAssertTrue(lines.filter { $0.hasPrefix("pick ") }.allSatisfy { $0.hasSuffix("=none") }, "\(lines)")
            return
        }
        let target = switchLine.split(separator: " ")[1]
        XCTAssertTrue(switchLine.hasSuffix("switched=true now=\(target)"), "the display shows the pick: \(switchLine)")
        XCTAssertTrue(lines.contains("restored now=\(current)"), "the display's own rate again: \(lines)")
    }

    /// Launches a dev session with the probe and `arguments`, and returns its lines once it is done.
    private func runProbe(_ arguments: [String]) -> [String] {
        launchDev(arguments: ["-probeDisplayModes", "YES"] + arguments)
        let probe = require("display.modes", timeout: 60, "the display modes probe")
        let finished = NSPredicate(format: "label CONTAINS 'done'")
        guard XCTWaiter.wait(for: [expectation(for: finished, evaluatedWith: probe)], timeout: 60) == .completed else {
            fail("the display modes run didn't finish: \(probe.label)")
            return []
        }
        let report = XCTAttachment(string: probe.label)
        report.name = "display modes"
        report.lifetime = .keepAlways
        add(report)
        return probe.label.split(separator: "\n").map(String.init)
    }
}
