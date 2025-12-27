import 'fullscreen_state_manager.dart';
import 'macos_window_delegate.dart';

/// Custom window delegate that manages fullscreen state
/// Note: Window manipulation (toolbar, titlebar, traffic lights) is now handled
/// directly in Swift's WindowDelegate. This class only updates Dart-side state.
class FullscreenWindowDelegate extends MacOSWindowDelegate {
  @override
  void windowWillEnterFullScreen() {
    FullscreenStateManager().setFullscreen(true);
  }

  @override
  void windowDidExitFullScreen() {
    FullscreenStateManager().setFullscreen(false);
  }
}
