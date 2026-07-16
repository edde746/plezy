import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/scroll_utils.dart';
import 'owned_focus_node_binding.dart';
import 'dpad_navigator.dart';
import 'dpad_select_long_press_controller.dart';
import 'key_event_utils.dart';

class ChipKeyCallbacks {
  final VoidCallback? onSelect;
  final VoidCallback? onLongPress;
  final VoidCallback? onNavigateDown;
  final VoidCallback? onNavigateUp;
  final VoidCallback? onNavigateLeft;
  final VoidCallback? onNavigateRight;
  final VoidCallback? onBack;

  const ChipKeyCallbacks({
    this.onSelect,
    this.onLongPress,
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
  final _focusNodeBinding = OwnedFocusNodeBinding();
  bool _isFocused = false;
  final _selectLongPress = DpadSelectLongPressController();

  /// Override to return the widget's optional external focus node.
  FocusNode? get widgetFocusNode;

  /// Override to return a debug label for the internal focus node.
  String get debugLabel;

  /// The active focus node (external if provided, otherwise internal).
  FocusNode get focusNode => _focusNodeBinding.node;

  /// Whether this widget is currently focused.
  bool get isFocused => _isFocused;

  /// Call this in your `initState` to set up the focus listener.
  void initFocusNode() {
    _focusNodeBinding.bind(externalNode: widgetFocusNode, listener: _onFocusChange, debugLabel: debugLabel);
  }

  /// Call this in your `didUpdateWidget` with the old widget's focusNode.
  void updateFocusNode(FocusNode? oldFocusNode) {
    if (oldFocusNode != widgetFocusNode) {
      _focusNodeBinding.bind(externalNode: widgetFocusNode, listener: _onFocusChange, debugLabel: debugLabel);
    }
  }

  /// Call this in your `dispose` to clean up the focus listener.
  void disposeFocusNode() {
    _focusNodeBinding.dispose();
    _selectLongPress.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      final hasFocus = focusNode.hasFocus;
      setState(() => _isFocused = hasFocus);
      if (!hasFocus) {
        _selectLongPress.reset();
      }
      // Same convention as FocusableTileStateMixin: a chip inside a
      // scrollable strip (TabChipStrip, filter bars) reveals itself on
      // focus; a no-op when no ancestor scrollable exists.
      if (focusNode.hasFocus) scrollContextToCenter(context);
    }
  }

  /// Shared key event handler for chip widgets.
  ///
  /// Handles common key patterns:
  /// - SELECT key -> onSelect (short press) / onLongPress (hold 500ms)
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

    if (SelectKeyUpSuppressor.consumeIfSuppressed(event)) {
      if (event is KeyUpEvent && key.isSelectKey) {
        _selectLongPress.reset();
      }
      return KeyEventResult.handled;
    }

    // SELECT key with long press support
    if (key.isSelectKey) {
      if (callbacks.onLongPress != null) {
        return _selectLongPress.handleKeyEvent(
          event,
          isOwnerActive: () => mounted,
          onShortPress: () => callbacks.onSelect?.call(),
          onLongPress: callbacks.onLongPress!,
        );
      } else if (callbacks.onSelect != null) {
        return handleOneShotSelect(event, callbacks.onSelect!);
      }
    }

    // Context menu key triggers long press directly
    if (event.isActionable && key.isContextMenuKey && callbacks.onLongPress != null) {
      _selectLongPress.reset();
      callbacks.onLongPress!();
      return KeyEventResult.handled;
    }

    if (!event.isActionable) {
      return KeyEventResult.ignored;
    }

    if (key.isLeftKey) {
      if (callbacks.onNavigateLeft != null) {
        callbacks.onNavigateLeft!();
        return KeyEventResult.handled;
      }
      // No callback - let parent handle (e.g., to focus sidebar)
      return KeyEventResult.ignored;
    }

    if (key.isRightKey) {
      if (callbacks.onNavigateRight != null) {
        callbacks.onNavigateRight!();
      }
      // Always consume RIGHT to prevent focus escape
      return KeyEventResult.handled;
    }

    if (key.isDownKey) {
      callbacks.onNavigateDown?.call();
      return KeyEventResult.handled;
    }

    if (key.isUpKey && callbacks.onNavigateUp != null) {
      callbacks.onNavigateUp!();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }
}
