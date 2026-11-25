#if os(macOS)
import AppKit
import Observation
import PlezyKit

/// Debug builds started with `-simulateDisplayModes YES` (UserDefaults' argument domain): a MacBook Pro's built-in
/// display, whose current mode (ProMotion, 120 Hz) has the fixed-rate variants 60, 59.94, 50, 48 and 47.95 Hz at the
/// same size, as CoreGraphics reports them. A display that offers one rate gets this one read and switched instead by
/// `DisplayModeSwitch`; the Settings row for the
/// frame-rate switch shows with it (`ApplePlatform.deviceFeatures`).
///
/// It counts what happened since the launch, for the UI tests' probe `player.display` (`PlayerProbes`):
/// `switches=<n> restores=<n> rate=<mHz>`, the modes set and the restores, and the rate the display shows now in
/// millihertz.
@MainActor
@Observable
final class SimulatedDisplayModes {
    /// The one `DisplayModeSwitch` uses; nil without the launch argument.
    static let shared: SimulatedDisplayModes? =
        UserDefaults.standard.bool(forKey: "simulateDisplayModes") ? SimulatedDisplayModes() : nil

    /// The rates CoreGraphics reports for a MacBook Pro's built-in display, ProMotion first.
    private static let rates = [120.0, 60.0, 59.93998718261719, 50.0, 48.0, 47.94999694824219]

    private(set) var switches = 0
    private(set) var restores = 0
    /// The rate shown: ProMotion's until a mode is set.
    private var rate = rates[0]

    var summary: String {
        "switches=\(switches) restores=\(restores) rate=\(Int((rate * 1000).rounded()))"
    }

    /// The variants at `screen`'s size in pixels (ids 1 to 6, ProMotion first), the current one the rate shown.
    func modes(on screen: NSScreen?) -> DisplayModeSwitch.Modes {
        let scale = screen?.backingScaleFactor ?? 2
        let size = screen?.frame.size ?? CGSize(width: 1512, height: 982)
        let width = Int32(size.width * scale)
        let height = Int32(size.height * scale)
        let variants = Self.rates.enumerated().map {
            DisplayModeSwitch.Mode(id: Int32($0.offset + 1), width: width, height: height, refreshRate: $0.element)
        }
        return DisplayModeSwitch.Modes(current: variants.first { $0.refreshRate == rate } ?? variants[0], variants: variants)
    }

    /// Shows `mode`'s rate when it is one of the variants: whether it was set.
    func set(_ mode: DisplayMode) -> Bool {
        guard Self.rates.contains(mode.refreshRate) else { return false }
        if mode.refreshRate != rate {
            rate = mode.refreshRate
            switches += 1
        }
        return true
    }

    /// Back to ProMotion, as the user's configuration has it.
    func restore() {
        rate = Self.rates[0]
        restores += 1
    }
}
#endif
