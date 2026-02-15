/// Abstract class for receiving macOS window delegate callbacks.
/// Extend this class and register with MacOSWindowService to receive
/// fullscreen transition events.
abstract class MacOSWindowDelegate {
  /// Called when the window is about to enter fullscreen mode.
  // ignore: no-empty-block - default no-op, subclasses override as needed
  void windowWillEnterFullScreen() {}

  /// Called when the window has entered fullscreen mode.
  // ignore: no-empty-block - default no-op, subclasses override as needed
  void windowDidEnterFullScreen() {}

  /// Called when the window is about to exit fullscreen mode.
  // ignore: no-empty-block - default no-op, subclasses override as needed
  void windowWillExitFullScreen() {}

  /// Called when the window has exited fullscreen mode.
  // ignore: no-empty-block - default no-op, subclasses override as needed
  void windowDidExitFullScreen() {}
}
