#if os(tvOS)
import PlezyKit
import SwiftUI
import UIKit

/// Debug builds started with `-probeDisplayCriteria YES` (and `-simulateMatchContent YES`, the simulated TV): the
/// TV's criteria for a run of video formats, through a player's surface as a playback drives it (`VideoSurface`'s plan
/// and formats, `AppleDisplayCriteria`, `DisplayCriteria` and its wait for the mode switch), without playing a file.
/// Each step reads `<name>: criteria=<what DisplayCriteria last wrote> ready=<ms until the surface said the display was
/// ready> writes=<n> switches=<n>`, and once the run is over `done readyWhileSwitching=<n> clears=<n>`. The steps:
/// SDR at 23.976 fps, HDR10, Dolby Vision profile 7 and profile 8, the same profile 8 again (no write, ready at once),
/// the Hdr setting turned off during the playback (the plan again: SDR, no reload), and the playback's end (the
/// criteria cleared).
@MainActor
@Observable
final class DisplayCriteriaRun {
    static let shared: DisplayCriteriaRun? =
        UserDefaults.standard.bool(forKey: "probeDisplayCriteria") ? DisplayCriteriaRun() : nil

    private(set) var lines: [String] = []
    private var started = false

    func start(in window: UIWindow) {
        guard !started else { return }
        started = true
        Task { await run(in: window) }
    }

    private func run(in window: UIWindow) async {
        let surface = VideoSurface(settings: DeviceSettings.companion.DEFAULT)
        surface.frame = CGRect(x: 0, y: 0, width: 16, height: 9)
        window.addSubview(surface)
        surface.apply(Self.plan(hdrOutput: true)) {}
        let ntsc24 = 24000.0 / 1001
        let sdr = VideoInfo(
            width: 1920, height: 1080, codec: nil, fps: KotlinDouble(double: ntsc24), dynamicRange: .sdr, doviProfile: nil,
            rotation: 0, sigPeak: nil, gamma: "bt.1886", primaries: "bt.709", colorMatrix: "bt.709"
        )
        let hdr10 = VideoInfo(
            width: 3840, height: 2160, codec: nil, fps: KotlinDouble(double: ntsc24), dynamicRange: .hdr10, doviProfile: nil,
            rotation: 0, sigPeak: KotlinDouble(double: 10), gamma: "pq", primaries: "bt.2020", colorMatrix: "bt.2020-ncl"
        )
        func dolbyVision(_ profile: Int32) -> VideoInfo {
            VideoInfo(
                width: 3840, height: 2160, codec: nil, fps: KotlinDouble(double: ntsc24), dynamicRange: .dolbyVision,
                doviProfile: KotlinInt(int: profile), rotation: 0, sigPeak: KotlinDouble(double: 10), gamma: "pq",
                primaries: "bt.2020", colorMatrix: "bt.2020-ncl"
            )
        }
        await step("sdr23976") { surface.present(DisplayFormat(video: sdr, doviLevel: nil), completion: $0) }
        await step("hdr10") { surface.present(DisplayFormat(video: hdr10, doviLevel: nil), completion: $0) }
        await step("dvP7") { surface.present(DisplayFormat(video: dolbyVision(7), doviLevel: 6), completion: $0) }
        await step("dvP8") { surface.present(DisplayFormat(video: dolbyVision(8), doviLevel: 6), completion: $0) }
        await step("dvP8again") { surface.present(DisplayFormat(video: dolbyVision(8), doviLevel: 6), completion: $0) }
        await step("hdrOff") { surface.apply(Self.plan(hdrOutput: false), completion: $0) }
        surface.endPlayback()
        // The end clears a main-queue turn later.
        try? await Task.sleep(for: .milliseconds(100))
        surface.removeFromSuperview()
        let reading = DisplaySwitchReading.shared
        lines.append("done readyWhileSwitching=\(reading.readyWhileSwitching) clears=\(reading.clears)")
    }

    private func step(_ name: String, _ action: (@escaping @Sendable () -> Void) -> Void) async {
        let start = ContinuousClock.now
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            action { continuation.resume() }
        }
        let elapsed = ContinuousClock.now - start
        let milliseconds = elapsed.components.seconds * 1000 + elapsed.components.attoseconds / 1_000_000_000_000_000
        let reading = DisplaySwitchReading.shared
        lines.append("\(name): criteria=\(reading.criteria) ready=\(milliseconds) writes=\(reading.writes) switches=\(reading.switches)")
    }

    private static func plan(hdrOutput: Bool) -> OutputPlan {
        OutputPlan(
            frameRate: nil, mode: nil, hdr: hdrOutput, hdrOutput: hdrOutput, enableHdr: false, switchDelaySeconds: 0,
            audioPassthrough: false, dolbyVisionConversion: .auto
        )
    }
}

/// Debug builds: the run's lines (`DisplayCriteriaRun`), one per line, as the value of an element the UI tests read
/// (`display.criteria`); it starts the run once it is in a window.
struct DisplayCriteriaProbe: View {
    let run: DisplayCriteriaRun

    var body: some View {
        WindowReader { run.start(in: $0) }
            .frame(width: 1, height: 1)
            .accessibilityElement()
            .accessibilityValue(run.lines.joined(separator: "\n"))
            .accessibilityIdentifier("display.criteria")
            .allowsHitTesting(false)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
    }
}

/// Calls `found` with the window it is in, once it is in one.
private struct WindowReader: UIViewRepresentable {
    let found: @MainActor (UIWindow) -> Void

    func makeUIView(context: Context) -> Probe { Probe(found: found) }
    func updateUIView(_ uiView: Probe, context: Context) {}

    final class Probe: UIView {
        let found: @MainActor (UIWindow) -> Void

        init(found: @escaping @MainActor (UIWindow) -> Void) {
            self.found = found
            super.init(frame: .zero)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if let window { found(window) }
        }
    }
}
#endif
