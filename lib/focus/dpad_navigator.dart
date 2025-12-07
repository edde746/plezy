import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A widget that provides global D-pad/keyboard navigation handling.
///
/// Wrap this around your MaterialApp or main content to enable:
/// - Back navigation with Escape/Back/GamepadB
/// - Focus traversal with arrow keys (handled by Flutter's focus system)
///
/// Example:
/// ```dart
/// DpadNavigator(
///   child: MaterialApp(...),
/// )
/// ```
class DpadNavigator extends StatelessWidget {
  /// The child widget (typically MaterialApp).
  final Widget child;

  /// Whether D-pad navigation is enabled.
  final bool enabled;

  /// Called when back navigation is triggered.
  /// If null, uses Navigator.maybePop().
  final VoidCallback? onBack;

  const DpadNavigator({
    super.key,
    required this.child,
    this.enabled = true,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: child,
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // Handle back navigation
    if (_isBackKey(event.logicalKey)) {
      if (onBack != null) {
        onBack!();
        return KeyEventResult.handled;
      }

      // Try to pop navigation if we have a context
      final context = node.context;
      if (context != null) {
        final navigator = Navigator.maybeOf(context);
        if (navigator != null && navigator.canPop()) {
          navigator.pop();
          return KeyEventResult.handled;
        }
      }
    }

    // Arrow keys and D-pad directions are handled by Flutter's focus system
    // We don't need to intercept them here

    return KeyEventResult.ignored;
  }

  bool _isBackKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.browserBack ||
        key == LogicalKeyboardKey.gameButtonB;
  }
}

/// Extension methods for checking D-pad related keys.
extension DpadKeyExtension on LogicalKeyboardKey {
  /// Whether this key is a D-pad directional key.
  bool get isDpadDirection {
    return this == LogicalKeyboardKey.arrowUp ||
        this == LogicalKeyboardKey.arrowDown ||
        this == LogicalKeyboardKey.arrowLeft ||
        this == LogicalKeyboardKey.arrowRight;
  }

  /// Whether this key is a select/activate key.
  bool get isSelectKey {
    return this == LogicalKeyboardKey.select ||
        this == LogicalKeyboardKey.enter ||
        this == LogicalKeyboardKey.numpadEnter ||
        this == LogicalKeyboardKey.gameButtonA;
  }

  /// Whether this key is a back/cancel key.
  bool get isBackKey {
    return this == LogicalKeyboardKey.escape ||
        this == LogicalKeyboardKey.goBack ||
        this == LogicalKeyboardKey.browserBack ||
        this == LogicalKeyboardKey.gameButtonB;
  }

  /// Whether this key is a context menu key.
  bool get isContextMenuKey {
    return this == LogicalKeyboardKey.contextMenu ||
        this == LogicalKeyboardKey.gameButtonX;
  }

  /// Whether this key moves focus left.
  bool get isLeftKey {
    return this == LogicalKeyboardKey.arrowLeft;
  }

  /// Whether this key moves focus right.
  bool get isRightKey {
    return this == LogicalKeyboardKey.arrowRight;
  }

  /// Whether this key moves focus up.
  bool get isUpKey {
    return this == LogicalKeyboardKey.arrowUp;
  }

  /// Whether this key moves focus down.
  bool get isDownKey {
    return this == LogicalKeyboardKey.arrowDown;
  }
}
