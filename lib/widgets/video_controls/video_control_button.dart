import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../focus/focusable_wrapper.dart';

/// A standardized button for video player controls with improved tap targets.
///
/// This widget ensures consistent tap target sizing across all video control
/// buttons without changing their visual appearance. The larger tap area makes
/// buttons easier to interact with, especially on mobile devices.
class VideoControlButton extends StatelessWidget {
  /// The icon to display in the button.
  final IconData icon;

  /// Called when the button is tapped.
  final VoidCallback? onPressed;

  /// The color of the icon. Defaults to white, or amber if [isActive] is true.
  final Color? color;

  /// Optional tooltip text shown on hover or long press.
  final String? tooltip;

  /// Optional semantic label for screen readers.
  /// If not provided, falls back to tooltip.
  final String? semanticLabel;

  /// Whether this button represents an active state (e.g., a feature is enabled).
  /// When true, the icon color defaults to amber instead of white.
  final bool isActive;

  /// Optional FocusNode for D-pad/keyboard navigation.
  /// When provided, the button becomes focusable with visual focus indicator.
  final FocusNode? focusNode;

  /// Custom key event handler for focus navigation.
  final KeyEventResult Function(FocusNode, KeyEvent)? onKeyEvent;

  /// Called when focus changes.
  final ValueChanged<bool>? onFocusChange;

  /// Whether this button should autofocus when first built.
  final bool autofocus;

  const VideoControlButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.tooltip,
    this.semanticLabel,
    this.isActive = false,
    this.focusNode,
    this.onKeyEvent,
    this.onFocusChange,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the effective color: explicit color > active amber > default white
    final effectiveColor = color ?? (isActive ? Colors.amber : Colors.white);

    final button = IconButton(
      icon: Icon(icon, color: effectiveColor),
      onPressed: onPressed,
      tooltip: tooltip,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );

    Widget result = semanticLabel != null
        ? Semantics(
            label: semanticLabel,
            button: true,
            excludeSemantics: true,
            child: button,
          )
        : button;

    // Wrap with FocusableWrapper when focusNode is provided
    if (focusNode != null) {
      result = FocusableWrapper(
        focusNode: focusNode,
        onSelect: onPressed,
        onKeyEvent: onKeyEvent,
        onFocusChange: onFocusChange,
        autofocus: autofocus,
        semanticLabel: semanticLabel,
        borderRadius: 20, // Circular for icon buttons
        autoScroll: false, // Video controls don't scroll
        useBackgroundFocus: true, // Use background highlight for video controls
        child: result,
      );
    }

    return result;
  }
}
