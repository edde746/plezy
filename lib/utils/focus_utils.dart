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

  /// Restore a captured menu destination only while its owner and live leaf
  /// still allow it. Unlike initial focus, this must not queue a detached node.
  static void restoreFocusAfterBuild(State state, FocusNode focusNode) {
    // A post-frame callback may not run until this node is attached again.
    // Do not let an already-detached capture become a future focus request.
    if (focusNode.parent == null || !focusNode.canRequestFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!state.mounted) return;
      final destination = focusNode.context;
      if (destination == null || !destination.mounted || focusNode.parent == null || !focusNode.canRequestFocus) return;
      if (!(ModalRoute.of(state.context)?.isCurrent ?? true)) return;
      focusNode.requestFocus();
    });
  }
}
