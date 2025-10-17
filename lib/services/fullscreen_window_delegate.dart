import 'package:macos_window_utils/macos_window_utils.dart';
import 'package:macos_window_utils/macos/ns_window_delegate.dart';
import 'package:macos_window_utils/macos/ns_window_button_type.dart';
import 'package:flutter/material.dart' show Offset;
import 'fullscreen_state_manager.dart';

/// Custom window delegate that manages titlebar configuration during fullscreen transitions
class FullscreenWindowDelegate extends NSWindowDelegate {
  static const double _customButtonY = 21.0;

  @override
  void windowWillEnterFullScreen() {
    // Notify global state manager
    FullscreenStateManager().setFullscreen(true);

    // Remove toolbar and restore default titlebar before entering fullscreen
    _prepareForFullscreen();
  }

  @override
  void windowWillExitFullScreen() {
    // Hide title and make transparent immediately (safe to do before transition)
    WindowManipulator.hideTitle();
    WindowManipulator.makeTitlebarTransparent();
  }

  @override
  void windowDidExitFullScreen() {
    // Notify global state manager
    FullscreenStateManager().setFullscreen(false);

    // Add toolbar and reposition traffic lights after transition completes
    WindowManipulator.addToolbar();

    // Restore custom traffic light positions
    WindowManipulator.overrideStandardWindowButtonPosition(
      buttonType: NSWindowButtonType.closeButton,
      offset: const Offset(20, _customButtonY),
    );
    WindowManipulator.overrideStandardWindowButtonPosition(
      buttonType: NSWindowButtonType.miniaturizeButton,
      offset: const Offset(40, _customButtonY),
    );
    WindowManipulator.overrideStandardWindowButtonPosition(
      buttonType: NSWindowButtonType.zoomButton,
      offset: const Offset(60, _customButtonY),
    );
  }

  /// Prepare titlebar for fullscreen mode
  void _prepareForFullscreen() {
    WindowManipulator.removeToolbar();
    WindowManipulator.showTitle();
    WindowManipulator.makeTitlebarOpaque();

    // Set traffic lights to standard fullscreen positions (null = default)
    WindowManipulator.overrideStandardWindowButtonPosition(
      buttonType: NSWindowButtonType.closeButton,
      offset: null,
    );
    WindowManipulator.overrideStandardWindowButtonPosition(
      buttonType: NSWindowButtonType.miniaturizeButton,
      offset: null,
    );
    WindowManipulator.overrideStandardWindowButtonPosition(
      buttonType: NSWindowButtonType.zoomButton,
      offset: null,
    );
  }
}
