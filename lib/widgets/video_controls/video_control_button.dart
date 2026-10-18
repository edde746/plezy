import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';

import '../../focus/focus_theme.dart';
import '../../focus/focusable_wrapper.dart';
import 'widgets/player_focus_disc.dart';

/// A standardized icon button for the video player's control rows.
///
/// Guarantees a 40px tap target without changing the idle appearance. With a
/// [focusNode] it is D-pad/keyboard focusable and shows the player's focus
/// treatment: a solid disc with the icon inverted ([PlayerFocusDisc]), scaled
/// by [FocusTheme.playerControlFocusScale].
class VideoControlButton extends StatelessWidget {
  final IconData icon;

  final VoidCallback? onPressed;

  /// The color of the icon. Defaults to white, or amber if [isActive] is true.
  final Color? color;

  final double iconSize;

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
    this.iconSize = 24,
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
    final idleColor = color ?? (isActive ? Colors.amber : Colors.white);
    final effectiveSemanticLabel = semanticLabel ?? tooltip;

    Widget button(Color iconColor) => IconButton(
      icon: AppIcon(icon, fill: 1, color: iconColor, size: iconSize),
      iconSize: iconSize,
      onPressed: onPressed,
      tooltip: tooltip,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );

    if (focusNode != null) {
      return FocusableWrapper(
        focusNode: focusNode,
        onSelect: onPressed,
        onKeyEvent: onKeyEvent,
        onFocusChange: onFocusChange,
        autofocus: autofocus,
        semanticLabel: effectiveSemanticLabel,
        semanticValue: semanticValue,
        checked: checked,
        autoScroll: false,
        delegateFocusBorder: true,
        focusScale: FocusTheme.playerControlFocusScale,
        child: PlayerFocusDisc(
          iconColor: idleColor,
          isActive: isActive,
          builder: (context, iconColor) => button(iconColor),
        ),
      );
    }

    if (effectiveSemanticLabel == null) return button(idleColor);
    return Semantics(
      label: effectiveSemanticLabel,
      value: semanticValue,
      button: true,
      enabled: onPressed != null,
      checked: checked,
      onTap: onPressed,
      excludeSemantics: true,
      child: button(idleColor),
    );
  }
}
