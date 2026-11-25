import AppKit
import OSLog
import PlezyKit

/// The Mac's side of the forced frame-rate switch: the shared `OutputPolicy` picks a mode (with the MatchFrameRate
/// setting on, and only while the player is full screen) among the modes read here, and one playback's switch
/// (`VideoSurface`) sets it on the display its window is on, and puts the display back.
///
/// The modes offered are the refresh-rate variants of the display's current mode: the same size in points and in
/// pixels, so a switch never changes the desktop's resolution or scaling. On a MacBook Pro's built-in display these are
/// ProMotion (reported as 120 Hz) and its fixed rates (60, 59.94, 50, 48 and 47.95 Hz): ProMotion can't hold a frame
/// longer than 24 Hz's, so 23.976 fps film plays evenly only at the fixed 47.95 Hz. On an external display they are the
/// rates it offers at its current resolution. CoreGraphics reports each rate exactly (59.94 as 59.9399…), which is
/// what the policy compares; a mode whose rate it doesn't know (0) is left out.
///
/// A switch is app-scoped (`.forAppOnly`): macOS gives the display back to the user's configuration when the app quits
/// or crashes, and a restore asks for that configuration (`CGRestorePermanentDisplayConfiguration`). The player reports
/// full screen as soon as it asks for it, while the window still animates into its space: a switch asked for then
/// waits until the window is in (or drops when it leaves instead, or when no notification came within
/// `transitionTimeout`: a window that fails to enter full screen posts none), so the display isn't reconfigured under
/// the transition. The mode set is the variant of the display's current mode with the asked-for size whose rate is
/// within 0.01 Hz of the asked-for one.
///
/// Debug builds started with `-simulateDisplayModes YES` read and switch the simulated display
/// (`SimulatedDisplayModes`) instead.
@MainActor
final class DisplayModeSwitch: NSObject {
    /// One mode as the policy takes it: the id is CoreGraphics' `ioDisplayModeID`, the size in pixels.
    struct Mode: Equatable, Sendable {
        let id: Int32
        let width: Int32
        let height: Int32
        let refreshRate: Double

        var displayMode: DisplayMode {
            DisplayMode(id: id, width: width, height: height, refreshRate: refreshRate)
        }
    }

    /// A display's current mode and its refresh-rate variants (the current one included).
    struct Modes: Sendable {
        let current: Mode
        let variants: [Mode]
    }

    private let window: () -> NSWindow?
    /// The display shows a mode this playback set.
    private var switched = false
    /// The window is on its way into full screen.
    private var entering = false
    /// The mode to set once the window is in full screen, and who hears whether it was; the number tells a newer one.
    private var pending: (mode: DisplayMode, done: @MainActor (Bool) -> Void, number: Int)?
    private var pendingNumber = 0

    /// How long a switch waits for the window to finish entering full screen.
    private static let transitionTimeout: DispatchTimeInterval = .seconds(3)

    private static let log = Logger(subsystem: "com.edde746.plezy", category: "display")

    /// Switches the display of `window()`'s window, read when a mode is set.
    init(window: @escaping () -> NSWindow?) {
        self.window = window
        super.init()
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(willEnterFullScreen), name: NSWindow.willEnterFullScreenNotification, object: nil)
        center.addObserver(self, selector: #selector(didEnterFullScreen), name: NSWindow.didEnterFullScreenNotification, object: nil)
        center.addObserver(self, selector: #selector(willExitFullScreen), name: NSWindow.willExitFullScreenNotification, object: nil)
    }

    /// Sets `mode` (one of `modes(on:)`'s variants), once the window is in full screen; nil puts the display back.
    /// `done` hears once whether the display switched to it (false: it showed it already, it couldn't, the window
    /// didn't enter full screen, or a newer request or a restore came first).
    func apply(_ mode: DisplayMode?, done: @escaping @MainActor (Bool) -> Void) {
        guard let mode else {
            restore()
            return done(false)
        }
        dropPending()
        guard entering else { return done(set(mode)) }
        pendingNumber += 1
        let number = pendingNumber
        pending = (mode, done, number)
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.transitionTimeout) { [weak self] in
            MainActor.assumeIsolated {
                guard let self, self.pending?.number == number else { return }
                Self.log.notice("display mode: no full screen notification within the timeout")
                self.finishEntering(entered: self.window()?.styleMask.contains(.fullScreen) == true)
            }
        }
    }

    /// Puts the display back as it was before this playback switched it.
    func restore() {
        dropPending()
        guard switched else { return }
        switched = false
        #if DEBUG
        if let simulated = SimulatedDisplayModes.shared {
            simulated.restore()
            return
        }
        #endif
        CGRestorePermanentDisplayConfiguration()
        Self.log.notice("display mode restored")
    }

    /// The current mode of `screen`'s display and its refresh-rate variants; nil where the display can't be read.
    static func modes(on screen: NSScreen?) -> Modes? {
        #if DEBUG
        if let simulated = SimulatedDisplayModes.shared { return simulated.modes(on: screen) }
        #endif
        guard let display = screen.flatMap(displayID), let current = CGDisplayCopyDisplayMode(display) else { return nil }
        return Modes(current: describe(current), variants: rateVariants(of: current, on: display).map(describe))
    }

    /// Sets `mode` on the window's display: whether the display switched to it (false when it showed it already).
    private func set(_ mode: DisplayMode) -> Bool {
        #if DEBUG
        if let simulated = SimulatedDisplayModes.shared {
            let before = simulated.switches
            guard simulated.set(mode) else { return false }
            switched = true
            return simulated.switches != before
        }
        #endif
        guard let display = window()?.screen.flatMap(Self.displayID), let current = CGDisplayCopyDisplayMode(display) else {
            Self.log.error("display mode \(Self.describe(mode), privacy: .public) not set: no display")
            return false
        }
        // The window may have moved to another display since the playback read the modes: the mode must be one of
        // this display's.
        let target = Self.rateVariants(of: current, on: display).first {
            $0.pixelWidth == Int(mode.width) && $0.pixelHeight == Int(mode.height) && abs($0.refreshRate - mode.refreshRate) < 0.01
        }
        guard let target else {
            Self.log.error("display mode \(Self.describe(mode), privacy: .public) not set: the display doesn't offer it")
            return false
        }
        if target.ioDisplayModeID == current.ioDisplayModeID { return false }
        var config: CGDisplayConfigRef?
        guard CGBeginDisplayConfiguration(&config) == .success, let config else {
            Self.log.error("display mode \(Self.describe(mode), privacy: .public) not set: no configuration")
            return false
        }
        guard CGConfigureDisplayWithDisplayMode(config, display, target, nil) == .success else {
            CGCancelDisplayConfiguration(config)
            Self.log.error("display mode \(Self.describe(mode), privacy: .public) not set: refused")
            return false
        }
        let result = CGCompleteDisplayConfiguration(config, .forAppOnly)
        guard result == .success else {
            Self.log.error("display mode \(Self.describe(mode), privacy: .public) not set: error \(result.rawValue)")
            return false
        }
        switched = true
        Self.log.notice("display mode \(current.refreshRate) Hz -> \(target.refreshRate) Hz")
        return true
    }

    @objc private func willEnterFullScreen(_ notification: Notification) {
        guard notification.object as? NSWindow === window() else { return }
        entering = true
    }

    @objc private func didEnterFullScreen(_ notification: Notification) {
        guard notification.object as? NSWindow === window() else { return }
        finishEntering(entered: true)
    }

    @objc private func willExitFullScreen(_ notification: Notification) {
        guard notification.object as? NSWindow === window() else { return }
        finishEntering(entered: false)
    }

    /// The window entered full screen, or didn't: the switch waiting for it is set, or dropped.
    private func finishEntering(entered: Bool) {
        entering = false
        guard let pending else { return }
        self.pending = nil
        pending.done(entered && set(pending.mode))
    }

    /// The switch waiting for full screen gives way: it hears it didn't switch.
    private func dropPending() {
        guard let pending else { return }
        self.pending = nil
        pending.done(false)
    }

    private static func displayID(of screen: NSScreen) -> CGDirectDisplayID? {
        (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
    }

    /// The modes with `current`'s size in points and in pixels and a known rate. A HiDPI mode and its rate variants are
    /// listed only with the duplicate low-resolution modes shown; the pixel size tells them from their 1x twins.
    private static func rateVariants(of current: CGDisplayMode, on display: CGDirectDisplayID) -> [CGDisplayMode] {
        let options = [kCGDisplayShowDuplicateLowResolutionModes: true] as CFDictionary
        let modes = (CGDisplayCopyAllDisplayModes(display, options) as? [CGDisplayMode]) ?? []
        return modes.filter {
            $0.isUsableForDesktopGUI() && $0.refreshRate > 0 && $0.width == current.width && $0.height == current.height
                && $0.pixelWidth == current.pixelWidth && $0.pixelHeight == current.pixelHeight
        }
    }

    private static func describe(_ mode: CGDisplayMode) -> Mode {
        Mode(id: Int32(mode.ioDisplayModeID), width: Int32(mode.pixelWidth), height: Int32(mode.pixelHeight), refreshRate: mode.refreshRate)
    }

    private static func describe(_ mode: DisplayMode) -> String {
        "\(mode.width)x\(mode.height)@\(mode.refreshRate)"
    }
}
