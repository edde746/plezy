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
/// by [FocusTheme.playerControlFocusScale]. With a [label] it becomes a pill
/// showing the icon and the label, and the focus fill follows the pill.
class VideoControlButton extends StatelessWidget {
  final IconData icon;

  final VoidCallback? onPressed;

  /// The color of the icon. Defaults to white, or amber if [isActive] is true.
  final Color? color;

  final double iconSize;

  /// Optional tooltip text shown on hover or long press.
  final String? tooltip;

  /// Optional visible text beside the icon, for an action an icon alone does
  /// not name. Unlike [tooltip] it stays readable under D-pad focus, where a
  /// tooltip never shows. The text ellipsizes to fit, so a labelled button
  /// needs a bounded width (e.g. under `Expanded`); the icon always shows.
  final String? label;

  /// Optional semantic label for screen readers.
  /// If not provided, falls back to [label], then [tooltip].
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
    this.label,
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
    final label = this.label;
    final effectiveSemanticLabel = semanticLabel ?? label ?? tooltip;

    Widget button(Color iconColor) => label == null
        ? IconButton(
            icon: AppIcon(icon, fill: 1, color: iconColor, size: iconSize),
            iconSize: iconSize,
            onPressed: onPressed,
            tooltip: tooltip,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          )
        : Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onPressed,
              customBorder: const StadiumBorder(),
              child: SizedBox(
                height: 40,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppIcon(icon, fill: 1, color: iconColor, size: iconSize),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: iconColor, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
          borderRadius: label == null ? null : const BorderRadius.all(Radius.circular(20)),
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
