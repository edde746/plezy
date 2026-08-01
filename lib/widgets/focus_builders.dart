import 'package:flutter/material.dart';
import '../focus/focus_chrome.dart';
import '../focus/focus_theme.dart';
import '../focus/input_mode_tracker.dart';
import 'clickable_cursor.dart';

/// Shared builders for focusable widgets to reduce code duplication.
///
/// These builders provide consistent focus decoration patterns across
/// different focusable widgets (chips, cards, etc.).
class FocusBuilders {
  /// Builds a chip-style focusable widget with background color changes.
  ///
  /// Used by FocusableTabChip and FocusableFilterChip.
  ///
  /// Parameters:
  /// - [context]: Build context for theming
  /// - [focusNode]: The focus node for this widget
  /// - [isFocused]: Whether this widget currently has focus
  /// - [onKeyEvent]: Callback for handling key events
  /// - [onTap]: Callback for tap/click events
  /// - [padding]: Padding inside the chip
  /// - [backgroundColor]: Background color for the chip
  /// - [borderRadius]: Border radius for the chip (defaults to 20)
  /// - [child]: The content to display inside the chip
  static Widget buildFocusableChip({
    required BuildContext context,
    required FocusNode focusNode,
    required KeyEventResult Function(FocusNode, KeyEvent) onKeyEvent,
    required VoidCallback onTap,
    required String semanticLabel,
    bool? selected,
    required EdgeInsetsGeometry padding,
    required Color backgroundColor,
    double borderRadius = 20,
    required Widget child,
  }) {
    final duration = FocusTheme.getAnimationDuration(context);

    return Focus(
      focusNode: focusNode,
      onKeyEvent: onKeyEvent,
      child: Semantics(
        label: semanticLabel,
        button: true,
        selected: selected,
        onTap: onTap,
        excludeSemantics: true,
        child: ClickableCursor(
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: duration,
              curve: Curves.easeOutCubic,
              padding: padding,
              decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(borderRadius)),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a card-style wrapper with scale and border decoration but no [Focus]
  /// node — focus lives on an enclosing rail or screen that passes [isFocused]
  /// down.
  ///
  /// Used by the hub row, the TV browse rail, the cast strip and the extras row.
  /// Cards that own their focus node use [FocusableWrapper] instead; both share
  /// the same chrome through [buildFocusChrome].
  ///
  /// Parameters:
  /// - [context]: Build context for theming
  /// - [isFocused]: Whether this widget should appear focused
  /// - [onTap]: Callback for tap/click events
  /// - [onLongPress]: Callback for long press events
  /// - [borderRadius]: Border radius for the focus decoration
  /// - [child]: The content to display inside the wrapper
  static Widget buildLockedFocusWrapper({
    required BuildContext context,
    required bool isFocused,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    double borderRadius = FocusTheme.defaultBorderRadius,
    double focusScale = FocusTheme.focusScale,
    bool useFocusGlow = false,
    bool delegateFocusBorder = false,
    Size? glowSize,
    required Widget child,
  }) {
    final isKeyboardMode = InputModeTracker.isKeyboardMode(context);

    // In touch mode, no item ever shows focus effects — skip animated wrappers
    // entirely. This saves ~2 element levels per card on ARM32 Android phones.
    if (!isKeyboardMode) {
      return (onTap != null || onLongPress != null)
          ? ClickableCursor(
              child: GestureDetector(onTap: onTap, onLongPress: onLongPress, child: child),
            )
          : child;
    }

    final duration = FocusTheme.getAnimationDuration(context);
    final focusedWidget = AnimatedScale(
      scale: isFocused ? focusScale : 1.0,
      duration: duration,
      curve: Curves.easeOutCubic,
      child: buildFocusChrome(
        context,
        showFocus: isFocused,
        duration: duration,
        borderRadius: borderRadius,
        useFocusGlow: useFocusGlow,
        delegateFocusBorder: delegateFocusBorder,
        glowSize: glowSize,
        child: child,
      ),
    );

    // Wrap in GestureDetector if tap/long press handlers provided
    return (onTap != null || onLongPress != null)
        ? ClickableCursor(
            child: GestureDetector(onTap: onTap, onLongPress: onLongPress, child: focusedWidget),
          )
        : focusedWidget;
  }
}
