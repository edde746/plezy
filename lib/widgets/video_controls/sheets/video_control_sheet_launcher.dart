import 'package:flutter/material.dart';
import 'base_video_control_sheet.dart';

/// Helper class to launch video control sheets with consistent behavior
///
/// This eliminates the need for each sheet to duplicate the showSheet wrapper.
class VideoControlSheetLauncher {
  /// Show a video control sheet with consistent styling and callbacks
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    VoidCallback? onOpen,
    VoidCallback? onClose,
  }) {
    return BaseVideoControlSheet.showSheet<T>(context: context, onOpen: onOpen, onClose: onClose, builder: builder);
  }
}
