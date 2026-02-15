import 'package:flutter/material.dart';

import 'dpad_navigator.dart';
import 'key_event_utils.dart';

/// Callbacks for chip key event handling.
class ChipKeyCallbacks {
  /// Called when SELECT key is pressed.
  final VoidCallback? onSelect;

  /// Called when DOWN arrow is pressed.
  final VoidCallback? onNavigateDown;

  /// Called when UP arrow is pressed.
  final VoidCallback? onNavigateUp;

  /// Called when LEFT arrow is pressed.
  final VoidCallback? onNavigateLeft;

  /// Called when RIGHT arrow is pressed.
  final VoidCallback? onNavigateRight;

  /// Called when BACK key is pressed.
  final VoidCallback? onBack;

  const ChipKeyCallbacks({
    this.onSelect,
    this.onNavigateDown,
    this.onNavigateUp,
    this.onNavigateLeft,
    this.onNavigateRight,
    this.onBack,
  });
}

/// A mixin that provides common FocusNode lifecycle management for chip widgets.
///
/// This mixin handles:
/// - Internal/external FocusNode pattern
/// - `_isFocused` state tracking
/// - Listener setup in `initState`
/// - Listener handoff in `didUpdateWidget`
/// - Cleanup in `dispose`
///
/// To use this mixin:
/// 1. Add `with FocusableChipStateMixin<YourWidget>` to your State class
/// 2. Implement [widgetFocusNode] to return the widget's optional focusNode
/// 3. Implement [debugLabel] to return a debug label for the internal node
/// 4. Call [initFocusNode] in your `initState`
/// 5. Call [updateFocusNode] in your `didUpdateWidget`
/// 6. Call [disposeFocusNode] in your `dispose`
/// 7. Use [focusNode] and [isFocused] in your build method
mixin FocusableChipStateMixin<T extends StatefulWidget> on State<T> {
  FocusNode? _internalFocusNode;
  bool _isFocused = false;

  /// Override to return the widget's optional external focus node.
  FocusNode? get widgetFocusNode;

  /// Override to return a debug label for the internal focus node.
  String get debugLabel;

  /// The active focus node (external if provided, otherwise internal).
  FocusNode get focusNode {
    return widgetFocusNode ?? (_internalFocusNode ??= FocusNode(debugLabel: debugLabel));
  }

  /// Whether this widget is currently focused.
  bool get isFocused => _isFocused;

  /// Call this in your `initState` to set up the focus listener.
  void initFocusNode() {
    focusNode.addListener(_onFocusChange);
  }

  /// Call this in your `didUpdateWidget` with the old widget's focusNode.
  void updateFocusNode(FocusNode? oldFocusNode) {
    if (oldFocusNode != widgetFocusNode) {
      oldFocusNode?.removeListener(_onFocusChange);
      focusNode.addListener(_onFocusChange);
    }
  }

  /// Call this in your `dispose` to clean up the focus listener.
  void disposeFocusNode() {
    focusNode.removeListener(_onFocusChange);
    _internalFocusNode?.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() => _isFocused = focusNode.hasFocus);
    }
  }

  /// Shared key event handler for chip widgets.
  ///
  /// Handles common key patterns:
  /// - SELECT key -> onSelect
  /// - Arrow keys -> navigation callbacks
  /// - BACK key -> onBack
  ///
  /// Returns [KeyEventResult.handled] if the event was consumed,
  /// [KeyEventResult.ignored] otherwise.
  KeyEventResult handleChipKeyEvent(FocusNode _, KeyEvent event, ChipKeyCallbacks callbacks) {
    final key = event.logicalKey;

    if (callbacks.onBack != null) {
      final backResult = handleBackKeyAction(event, callbacks.onBack!);
      if (backResult != KeyEventResult.ignored) {
        return backResult;
      }
    }

    if (!event.isActionable) {
      return KeyEventResult.ignored;
    }

    // SELECT key activates the chip
    if (key.isSelectKey && callbacks.onSelect != null) {
      callbacks.onSelect!();
      return KeyEventResult.handled;
    }

    // LEFT arrow - call callback if provided, otherwise propagate to parent
    if (key.isLeftKey) {
      if (callbacks.onNavigateLeft != null) {
        callbacks.onNavigateLeft!();
        return KeyEventResult.handled;
      }
      // No callback - let parent handle (e.g., to focus sidebar)
      return KeyEventResult.ignored;
    }

    // RIGHT arrow - call callback if provided, otherwise consume to prevent escape
    if (key.isRightKey) {
      if (callbacks.onNavigateRight != null) {
        callbacks.onNavigateRight!();
      }
      // Always consume RIGHT to prevent focus escape
      return KeyEventResult.handled;
    }

    // DOWN arrow
    if (key.isDownKey) {
      callbacks.onNavigateDown?.call();
      return KeyEventResult.handled;
    }

    // UP arrow
    if (key.isUpKey && callbacks.onNavigateUp != null) {
      callbacks.onNavigateUp!();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }
}
