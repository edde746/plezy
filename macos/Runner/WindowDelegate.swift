import Cocoa
import FlutterMacOS

class WindowDelegate: NSObject, NSWindowDelegate {
    weak var channel: FlutterMethodChannel?
    weak var window: NSWindow?

    // Hardcoded presentation options for fullscreen mode
    // Auto-hide toolbar, menu bar, and dock when in fullscreen
    private let fullScreenPresentationOptions: NSApplication.PresentationOptions = [
        .fullScreen,
        .autoHideToolbar,
        .autoHideMenuBar,
        .autoHideDock
    ]

    // MARK: - Private Helpers

    private func emit(_ method: String) {
        channel?.invokeMethod(method, arguments: nil)
    }

    // MARK: - NSWindowDelegate

    func window(_ window: NSWindow, willUseFullScreenPresentationOptions proposedOptions: NSApplication.PresentationOptions) -> NSApplication.PresentationOptions {
        return fullScreenPresentationOptions
    }

    func windowWillEnterFullScreen(_ notification: Notification) {
        guard let window = window else { return }
        // Remove toolbar before entering fullscreen
        window.toolbar = nil
        // Show title and make titlebar opaque for native fullscreen look
        window.titleVisibility = .visible
        window.titlebarAppearsTransparent = false
        // Reset traffic light positions to default
        WindowUtilsPlugin.setTrafficLightPositions(custom: false, window: window)
        // Notify Dart for state management only
        emit("windowWillEnterFullScreen")
    }

    func windowDidEnterFullScreen(_ notification: Notification) {
        emit("windowDidEnterFullScreen")
    }

    func windowWillExitFullScreen(_ notification: Notification) {
        guard let window = window else { return }
        // Hide title and make titlebar transparent BEFORE exiting
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        emit("windowWillExitFullScreen")
    }

    func windowDidExitFullScreen(_ notification: Notification) {
        guard let window = window else { return }
        // Restore toolbar
        if let flutterVC = window.contentViewController {
            let toolbar = ForwardingToolbar(flutterViewController: flutterVC)
            window.toolbar = toolbar
        }
        // Restore custom traffic light positions
        WindowUtilsPlugin.setTrafficLightPositions(custom: true, window: window)
        emit("windowDidExitFullScreen")
    }
}
