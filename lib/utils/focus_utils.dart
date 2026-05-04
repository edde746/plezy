import 'package:flutter/widgets.dart';

class FocusUtils {
  FocusUtils._();

  /// Request focus on a FocusNode after the current frame completes.
  /// Safely checks if the State is still mounted before requesting focus.
  ///
  /// Usage:
  /// ```dart
  /// FocusUtils.requestFocusAfterBuild(this, _focusNode);
  /// ```
  static void requestFocusAfterBuild(State state, FocusNode focusNode) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.mounted) {
        focusNode.requestFocus();
      }
    });
  }
}
