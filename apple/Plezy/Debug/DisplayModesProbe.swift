#if os(macOS)
import AppKit
import PlezyKit
import SwiftUI

/// Debug builds started with `-probeDisplayModes YES`: the Mac's refresh-rate switch on the window's real display, as a
/// full screen playback drives it, without playing a file. It reads the display's current mode and its refresh-rate
/// variants (`DisplayModeSwitch.modes`), asks the shared policy for the mode of each common frame rate
/// (`OutputPolicy.bestRefreshRate`), sets the first pick that isn't the current mode (`DisplayModeSwitch.apply`), reads
/// the display again, restores it (`DisplayModeSwitch.restore`) and reads it once more. Lines: `modes=<Hz,…>
/// current=<Hz>`, `pick <fps>=<Hz|none>` per rate, then `switch <Hz> switched=<bool> now=<Hz>` and `restored now=<Hz>`
/// (or `switch none`), and `done`.
@MainActor
@Observable
final class DisplayModesRun {
    static let shared: DisplayModesRun? =
        UserDefaults.standard.bool(forKey: "probeDisplayModes") ? DisplayModesRun() : nil

    private(set) var lines: [String] = []
    private var started = false
    private var switched = false

    func start(in window: NSWindow) {
        guard !started else { return }
        started = true
        Task { await run(in: window) }
    }

    private func run(in window: NSWindow) async {
        guard let modes = DisplayModeSwitch.modes(on: window.screen) else {
            lines += ["no modes", "done"]
            return
        }
        let format = { (rate: Double) in String(format: "%.3f", rate) }
        lines.append("modes=\(modes.variants.map { format($0.refreshRate) }.joined(separator: ",")) current=\(format(modes.current.refreshRate))")
        var first: DisplayMode?
        for fps in [24000.0 / 1001, 24, 25, 30000.0 / 1001, 50, 60000.0 / 1001] {
            let pick = OutputPolicy.shared.bestRefreshRate(
                fps: fps,
                current: modes.current.displayMode,
                modes: modes.variants.map(\.displayMode)
            )
            lines.append("pick \(format(fps))=\(pick.map { format($0.refreshRate) } ?? "none")")
            if first == nil { first = pick }
        }
        guard let first else {
            lines += ["switch none", "done"]
            return
        }
        let modeSwitch = DisplayModeSwitch { [weak window] in window }
        modeSwitch.apply(first) { [weak self] in self?.switched = $0 }
        try? await Task.sleep(for: .seconds(2))
        let now = DisplayModeSwitch.modes(on: window.screen)?.current.refreshRate ?? 0
        lines.append("switch \(format(first.refreshRate)) switched=\(switched) now=\(format(now))")
        modeSwitch.restore()
        try? await Task.sleep(for: .seconds(2))
        let restored = DisplayModeSwitch.modes(on: window.screen)?.current.refreshRate ?? 0
        lines += ["restored now=\(format(restored))", "done"]
    }
}

/// Debug builds: the run's lines (`DisplayModesRun`), one per line, as the label of an element the UI tests read
/// (`display.modes`; the Mac doesn't report a plain element's value); it starts the run once it is in a window.
struct DisplayModesRunProbe: View {
    let run: DisplayModesRun

    var body: some View {
        WindowReader { run.start(in: $0) }
            .frame(width: 1, height: 1)
            .accessibilityElement()
            .accessibilityLabel(Text(verbatim: run.lines.joined(separator: "\n")))
            .accessibilityIdentifier("display.modes")
            .allowsHitTesting(false)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
    }
}

/// Calls `found` with the window it is in, once it is in one.
private struct WindowReader: NSViewRepresentable {
    let found: @MainActor (NSWindow) -> Void

    func makeNSView(context: Context) -> Probe { Probe(found: found) }
    func updateNSView(_ nsView: Probe, context: Context) {}

    final class Probe: NSView {
        let found: @MainActor (NSWindow) -> Void

        init(found: @escaping @MainActor (NSWindow) -> Void) {
            self.found = found
            super.init(frame: .zero)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if let window { found(window) }
        }
    }
}
#endif
