import Cocoa
import FlutterMacOS

class WindowDelegate: NSObject, NSWindowDelegate {
  weak var channel: FlutterMethodChannel?
  weak var window: NSWindow?

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

  // MARK: - NSWindowDelegate

  func window(
    _ window: NSWindow,
    willUseFullScreenPresentationOptions proposedOptions: NSApplication.PresentationOptions
  ) -> NSApplication.PresentationOptions {
    return fullScreenPresentationOptions
  }

  func windowWillEnterFullScreen(_ notification: Notification) {
    guard let window = window else { return }
    applyFullScreenChrome(to: window)
    emit("windowWillEnterFullScreen")
  }

  func windowDidEnterFullScreen(_ notification: Notification) {
    emit("windowDidEnterFullScreen")
  }

  func windowWillExitFullScreen(_ notification: Notification) {
    guard let window = window else { return }
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    emit("windowWillExitFullScreen")
  }

  func windowDidExitFullScreen(_ notification: Notification) {
    guard let window = window else { return }
    applyWindowedChrome(to: window)
    emit("windowDidExitFullScreen")
  }
}
