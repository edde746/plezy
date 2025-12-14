import 'package:flutter/widgets.dart';

/// Utility class for common focus operations
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

  /// Execute a callback after the current frame completes, with mounted check.
  /// The callback will only execute if the State is still mounted.
  ///
  /// Usage:
  /// ```dart
  /// FocusUtils.afterBuildIfMounted(this, () {
  ///   // do something
  /// });
  /// ```
  static void afterBuildIfMounted(State state, VoidCallback callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.mounted) {
        callback();
      }
    });
  }

  /// Execute a callback after the current frame completes, without mounted check.
  /// Use this when you don't need the mounted check or are managing it yourself.
  ///
  /// Usage:
  /// ```dart
  /// FocusUtils.afterBuild(() {
  ///   // do something
  /// });
  /// ```
  static void afterBuild(VoidCallback callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      callback();
    });
  }
}
