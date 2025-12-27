/// Abstract class for receiving macOS window delegate callbacks.
/// Extend this class and register with MacOSWindowService to receive
/// fullscreen transition events.
abstract class MacOSWindowDelegate {
  /// Called when the window is about to enter fullscreen mode.
  void windowWillEnterFullScreen() {}

  /// Called when the window has entered fullscreen mode.
  void windowDidEnterFullScreen() {}

  /// Called when the window is about to exit fullscreen mode.
  void windowWillExitFullScreen() {}

  /// Called when the window has exited fullscreen mode.
  void windowDidExitFullScreen() {}
}
