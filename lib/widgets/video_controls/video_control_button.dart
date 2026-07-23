import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';

import '../../focus/focusable_wrapper.dart';

/// A standardized button for video player controls with improved tap targets.
///
/// This widget ensures consistent tap target sizing across all video control
/// buttons without changing their visual appearance. The larger tap area makes
/// buttons easier to interact with, especially on mobile devices.
class VideoControlButton extends StatelessWidget {
  final IconData icon;

  final VoidCallback? onPressed;

  /// The color of the icon. Defaults to white, or amber if [isActive] is true.
  final Color? color;

  /// Optional tooltip text shown on hover or long press.
  final String? tooltip;

  /// Optional semantic label for screen readers.
  /// If not provided, falls back to tooltip.
  final String? semanticLabel;

  /// Optional current value announced after [semanticLabel].
  final String? semanticValue;

  /// Optional checked state for toggle-style controls.
  final bool? checked;

  /// Whether this button represents an active state (e.g., a feature is enabled).
  /// When true, the icon color defaults to amber instead of white.
  final bool isActive;

  /// Optional FocusNode for D-pad/keyboard navigation.
  /// When provided, the button becomes focusable with visual focus indicator.
  final FocusNode? focusNode;

  /// Custom key event handler for focus navigation.
  final KeyEventResult Function(FocusNode, KeyEvent)? onKeyEvent;

  final ValueChanged<bool>? onFocusChange;

  final bool autofocus;

  const VideoControlButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.tooltip,
    this.semanticLabel,
    this.semanticValue,
    this.checked,
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
      icon: AppIcon(icon, fill: 1, color: effectiveColor),
      onPressed: onPressed,
      tooltip: tooltip,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );

    final effectiveSemanticLabel = semanticLabel ?? tooltip;
    Widget result = button;

    if (focusNode != null) {
      result = FocusableWrapper(
        focusNode: focusNode,
        onSelect: onPressed,
        onKeyEvent: onKeyEvent,
        onFocusChange: onFocusChange,
        autofocus: autofocus,
        semanticLabel: effectiveSemanticLabel,
        semanticValue: semanticValue,
        checked: checked,
        borderRadius: 20, // Circular for icon buttons
        autoScroll: false, // Video controls don't scroll
        useBackgroundFocus: true, // Use background highlight for video controls
        child: result,
      );
    } else if (effectiveSemanticLabel != null) {
      result = Semantics(
        label: effectiveSemanticLabel,
        value: semanticValue,
        button: true,
        enabled: onPressed != null,
        checked: checked,
        onTap: onPressed,
        excludeSemantics: true,
        child: result,
      );
    }

    return result;
  }
}
