import Cocoa

/// Refresh-rate switching for the display showing the player window, behind
/// Dart's DisplayModeService (the Windows side is
/// windows/runner/mpv/display_mode_manager.cpp).
///
/// Only refresh-rate variants of the display's current mode are offered, the
/// same size in points and in pixels, so a switch never changes the desktop's
/// resolution or scaling. Rates go to Dart exactly as the mode reports them
/// (47.95, 59.94), not in Windows' whole hertz.
///
/// Switches are app-scoped (`.forAppOnly`): macOS hands every display back to
/// the user's own configuration when Plezy quits or crashes, so there is no
/// recovery record to keep, and restoring does the same thing on purpose.
final class DisplayModeManager {
  private struct PendingSwitch {
    let window: NSWindow
    let width: Int
    let height: Int
    let refreshRate: Double
    let completion: (Bool) -> Void
  }

  /// A window that fails to enter fullscreen posts no notification at all,
  /// so a switch waiting for the transition gives up after this long.
  private static let transitionTimeout: TimeInterval = 3

  private(set) var isModeChanged = false
  /// Dart learns of fullscreen at willEnter, while the window is still
  /// animating into its space. A switch asked for then runs once the window
  /// has entered, so the display is not reconfigured under the transition,
  /// and Dart gets its answer after the switch has run.
  private var enteringFullScreen = false
  private var pending: PendingSwitch?
  private var pendingGeneration = 0
  private var observers: [NSObjectProtocol] = []

  init() {
    let center = NotificationCenter.default
    func observe(_ name: Notification.Name, _ body: @escaping (DisplayModeManager) -> Void) -> NSObjectProtocol {
      center.addObserver(forName: name, object: nil, queue: .main) { [weak self] notification in
        guard let self, notification.object is MainFlutterWindow else { return }
        body(self)
      }
    }
    observers = [
      observe(NSWindow.willEnterFullScreenNotification) { $0.enteringFullScreen = true },
      observe(NSWindow.didEnterFullScreenNotification) { $0.finishEntering(entered: true) },
      observe(NSWindow.willExitFullScreenNotification) { $0.finishEntering(entered: false) },
    ]
  }

  deinit {
    observers.forEach { NotificationCenter.default.removeObserver($0) }
  }

  /// The current mode of the window's display as `width`, `height` (points)
  /// and `refreshRate` (Hz).
  func currentMode(on window: NSWindow) -> [String: Any]? {
    guard let display = Self.displayID(of: window), let mode = CGDisplayCopyDisplayMode(display) else {
      return nil
    }
    return Self.describe(mode)
  }

  /// The refresh-rate variants of the window display's current mode.
  func modes(on window: NSWindow) -> [[String: Any]] {
    guard let display = Self.displayID(of: window), let current = CGDisplayCopyDisplayMode(display) else {
      return []
    }
    return Self.rateVariants(of: current, on: display).map(Self.describe)
  }

  func setMode(
    on window: NSWindow, width: Int, height: Int, refreshRate: Double,
    completion: @escaping (Bool) -> Void
  ) {
    cancelPending()
    guard enteringFullScreen else {
      completion(apply(width: width, height: height, refreshRate: refreshRate, on: window))
      return
    }
    pendingGeneration += 1
    let generation = pendingGeneration
    pending = PendingSwitch(
      window: window, width: width, height: height, refreshRate: refreshRate, completion: completion)
    DispatchQueue.main.asyncAfter(deadline: .now() + Self.transitionTimeout) { [weak self] in
      guard let self, self.pending != nil, self.pendingGeneration == generation else { return }
      self.finishEntering(entered: window.styleMask.contains(.fullScreen))
    }
  }

  func restore() -> Bool {
    cancelPending()
    guard isModeChanged else { return true }
    CGRestorePermanentDisplayConfiguration()
    isModeChanged = false
    MpvLog.debug("[DisplayModeManager] Restored the user's display configuration")
    return true
  }

  private func finishEntering(entered: Bool) {
    enteringFullScreen = false
    guard let pending else { return }
    self.pending = nil
    let applied =
      entered
      && apply(width: pending.width, height: pending.height, refreshRate: pending.refreshRate, on: pending.window)
    pending.completion(applied)
  }

  private func cancelPending() {
    guard let pending else { return }
    self.pending = nil
    pending.completion(false)
  }

  private func apply(width: Int, height: Int, refreshRate: Double, on window: NSWindow) -> Bool {
    guard let display = Self.displayID(of: window), let current = CGDisplayCopyDisplayMode(display) else {
      return false
    }
    let target = Self.rateVariants(of: current, on: display).first {
      $0.width == width && $0.height == height && abs($0.refreshRate - refreshRate) < 0.01
    }
    guard let target else {
      MpvLog.debug("[DisplayModeManager] No \(width)x\(height) mode at \(refreshRate) Hz")
      return false
    }
    if target.ioDisplayModeID == current.ioDisplayModeID { return true }

    var config: CGDisplayConfigRef?
    guard CGBeginDisplayConfiguration(&config) == .success, let config else { return false }
    guard CGConfigureDisplayWithDisplayMode(config, display, target, nil) == .success else {
      CGCancelDisplayConfiguration(config)
      return false
    }
    guard CGCompleteDisplayConfiguration(config, .forAppOnly) == .success else { return false }
    isModeChanged = true
    MpvLog.debug(
      "[DisplayModeManager] Switched display \(display) from \(current.refreshRate) to \(target.refreshRate) Hz")
    return true
  }

  private static func displayID(of window: NSWindow) -> CGDirectDisplayID? {
    (window.screen?.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
  }

  /// Modes with the current mode's size in points and pixels. A HiDPI mode
  /// and its rate variants are listed only with the duplicate low-resolution
  /// modes shown; the pixel size then tells them apart from their 1x twins.
  private static func rateVariants(of current: CGDisplayMode, on display: CGDirectDisplayID) -> [CGDisplayMode] {
    let options = [kCGDisplayShowDuplicateLowResolutionModes: true] as CFDictionary
    let modes = (CGDisplayCopyAllDisplayModes(display, options) as? [CGDisplayMode]) ?? []
    return modes.filter {
      $0.isUsableForDesktopGUI() && $0.width == current.width && $0.height == current.height
        && $0.pixelWidth == current.pixelWidth && $0.pixelHeight == current.pixelHeight
    }
  }

  private static func describe(_ mode: CGDisplayMode) -> [String: Any] {
    ["width": mode.width, "height": mode.height, "refreshRate": mode.refreshRate]
  }
}
