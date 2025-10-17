import 'dart:io' show Platform;
import 'package:flutter/material.dart' show Offset;
import 'package:macos_window_utils/macos_window_utils.dart';
import 'package:macos_window_utils/macos/ns_window_button_type.dart';
import 'fullscreen_window_delegate.dart';

/// Service to manage macOS titlebar configuration
class MacOSTitlebarService {
  // Standard button Y position when using custom toolbar
  static const double _customButtonY = 21.0;

  /// Initialize the custom titlebar setup (transparent with toolbar)
  /// This configuration automatically handles fullscreen mode natively
  static Future<void> setupCustomTitlebar() async {
    if (!Platform.isMacOS) return;

    // Enable window delegate to use presentation options and fullscreen callbacks
    await WindowManipulator.initialize(enableWindowDelegate: true);

    // Register custom delegate to handle fullscreen transitions
    final delegate = FullscreenWindowDelegate();
    WindowManipulator.addNSWindowDelegate(delegate);

    // Make titlebar transparent but keep it functional
    await WindowManipulator.makeTitlebarTransparent();
    await WindowManipulator.hideTitle();
    await WindowManipulator.enableFullSizeContentView();

    // Add toolbar to create space for traffic lights in normal mode
    await WindowManipulator.addToolbar();

    // Set custom traffic light positions for normal mode
    await _setCustomButtonPositions();

    // Configure fullscreen presentation to auto-hide toolbar and menubar
    // This tells macOS to automatically hide the toolbar when entering fullscreen
    final presentationOptions = NSAppPresentationOptions.from({
      NSAppPresentationOption.fullScreen,
      NSAppPresentationOption.autoHideToolbar,
      NSAppPresentationOption.autoHideMenuBar,
      NSAppPresentationOption.autoHideDock,
    });
    presentationOptions.applyAsFullScreenPresentationOptions();
  }

  /// Set traffic light buttons to custom positions (with toolbar offset)
  static Future<void> _setCustomButtonPositions() async {
    await WindowManipulator.overrideStandardWindowButtonPosition(
      buttonType: NSWindowButtonType.closeButton,
      offset: const Offset(20, _customButtonY),
    );
    await WindowManipulator.overrideStandardWindowButtonPosition(
      buttonType: NSWindowButtonType.miniaturizeButton,
      offset: const Offset(40, _customButtonY),
    );
    await WindowManipulator.overrideStandardWindowButtonPosition(
      buttonType: NSWindowButtonType.zoomButton,
      offset: const Offset(60, _customButtonY),
    );
  }
}
