import '../utils/platform_helper.dart';
import 'fullscreen_window_delegate.dart';
import 'macos_window_service.dart';

/// Service to manage macOS titlebar configuration
class MacOSTitlebarService {
  static bool _initialized = false;

  /// Initialize the custom titlebar setup.
  ///
  /// Note: The initial window configuration (transparent titlebar, toolbar,
  /// button positions, fullscreen presentation options) is now applied in
  /// MainFlutterWindow.swift / WindowDelegate.swift BEFORE frame restoration
  /// to prevent the window from shrinking on launch.
  ///
  /// This method only sets up the Dart-side callbacks.
  static Future<void> setupCustomTitlebar() async {
    if (!AppPlatform.isMacOS || _initialized) return;
    _initialized = true;

    await MacOSWindowService.initialize(enableWindowDelegate: true);
    final delegate = FullscreenWindowDelegate();
    MacOSWindowService.addWindowDelegate(delegate);
  }
}
