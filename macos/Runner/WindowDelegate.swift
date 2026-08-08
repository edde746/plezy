import Cocoa
import FlutterMacOS

class WindowDelegate: NSObject, NSWindowDelegate {
  weak var channel: FlutterMethodChannel?
  weak var window: NSWindow?

  /// The delegate this one displaced, kept so plugins that read window events
  /// through their own delegate keep receiving them.
  ///
  /// A window has exactly one delegate, so installing ours silently cut off
  /// every plugin that installs its own — window_manager sources all of its
  /// Dart-side events (focus, blur, move, resize, maximize, minimize) from
  /// `NSWindowDelegate` callbacks and claims the slot when it initialises. It
  /// happens to initialise just before us, so its events stopped arriving
  /// entirely: `onWindowFocus` never fired, and the player's handler for it was
  /// dead code on macOS. Unimplemented callbacks reach it by message
  /// forwarding; the ones implemented below chain explicitly.
  weak var previousDelegate: NSWindowDelegate?

  // Hardcoded presentation options for fullscreen mode
  // Auto-hide toolbar, menu bar, and dock when in fullscreen
  private let fullScreenPresentationOptions: NSApplication.PresentationOptions = [
    .fullScreen,
    .autoHideToolbar,
    .autoHideMenuBar,
    .autoHideDock,
  ]

  // MARK: - Private Helpers

  private func emit(_ method: String) {
    channel?.invokeMethod(method, arguments: nil)
  }

  func syncWindowChrome() {
    guard let window = window else { return }
    if window.styleMask.contains(.fullScreen) {
      applyFullScreenChrome(to: window)
    } else {
      applyWindowedChrome(to: window)
    }
  }

  private func applyFullScreenChrome(to window: NSWindow) {
    window.toolbar = nil
    window.titleVisibility = .visible
    window.titlebarAppearsTransparent = false
    WindowUtilsPlugin.setTrafficLightsVisible(true, window: window)
    WindowUtilsPlugin.setTrafficLightPositions(custom: false, window: window)
  }

  private func applyWindowedChrome(to window: NSWindow) {
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.styleMask.insert(.fullSizeContentView)

    if window.toolbar == nil, let flutterVC = window.contentViewController {
      window.toolbar = ForwardingToolbar(flutterViewController: flutterVC)
    }

    WindowUtilsPlugin.setTrafficLightsVisible(true, window: window)
    WindowUtilsPlugin.setTrafficLightPositions(custom: true, window: window)
  }

  // MARK: - Delegate chaining

  // Everything this class does not implement is handed to the displaced
  // delegate by the runtime: `responds(to:)` claims its selectors so the
  // message is dispatched, and `forwardingTarget(for:)` then routes it there.
  // Callbacks implemented below are chained by hand instead, since claiming
  // them here would stop at this object.

  override func responds(to aSelector: Selector!) -> Bool {
    if super.responds(to: aSelector) { return true }
    return previousDelegate?.responds(to: aSelector) ?? false
  }

  override func forwardingTarget(for aSelector: Selector!) -> Any? {
    if super.responds(to: aSelector) { return nil }
    return previousDelegate
  }

  // MARK: - NSWindowDelegate

  func window(
    _ window: NSWindow,
    willUseFullScreenPresentationOptions proposedOptions: NSApplication.PresentationOptions
  ) -> NSApplication.PresentationOptions {
    // Not chained: these options are this app's own fullscreen presentation
    // choice, and only one answer can win.
    return fullScreenPresentationOptions
  }

  func windowWillEnterFullScreen(_ notification: Notification) {
    guard let window = window else { return }
    applyFullScreenChrome(to: window)
    // Notify Dart for state management only
    emit("windowWillEnterFullScreen")
    previousDelegate?.windowWillEnterFullScreen?(notification)
  }

  func windowDidEnterFullScreen(_ notification: Notification) {
    emit("windowDidEnterFullScreen")
    previousDelegate?.windowDidEnterFullScreen?(notification)
  }

  func windowWillExitFullScreen(_ notification: Notification) {
    guard let window = window else { return }
    // Hide title and make titlebar transparent BEFORE exiting
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    emit("windowWillExitFullScreen")
    previousDelegate?.windowWillExitFullScreen?(notification)
  }

  func windowDidExitFullScreen(_ notification: Notification) {
    guard let window = window else { return }
    applyWindowedChrome(to: window)
    emit("windowDidExitFullScreen")
    previousDelegate?.windowDidExitFullScreen?(notification)
  }
}
