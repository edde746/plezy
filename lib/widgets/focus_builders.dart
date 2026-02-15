import 'package:flutter/material.dart';
import '../focus/focus_theme.dart';
import '../focus/input_mode_tracker.dart';

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
    required EdgeInsetsGeometry padding,
    required Color backgroundColor,
    double borderRadius = 20,
    required Widget child,
  }) {
    final duration = FocusTheme.getAnimationDuration(context);

    return Focus(
      focusNode: focusNode,
      onKeyEvent: onKeyEvent,
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
    );
  }

  /// Builds a card-style focusable widget with scale and border decoration.
  ///
  /// Used by FocusableMediaCard and _LockedHubItemWrapper.
  ///
  /// Parameters:
  /// - [context]: Build context for theming
  /// - [focusNode]: The focus node for this widget (optional for locked wrappers)
  /// - [isFocused]: Whether this widget currently has focus
  /// - [onKeyEvent]: Callback for handling key events (optional for locked wrappers)
  /// - [onTap]: Callback for tap/click events
  /// - [onLongPress]: Callback for long press events
  /// - [borderRadius]: Border radius for the focus decoration
  /// - [child]: The content to display inside the card
  static Widget buildFocusableCard({
    required BuildContext context,
    FocusNode? focusNode,
    required bool isFocused,
    KeyEventResult Function(FocusNode, KeyEvent)? onKeyEvent,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    double borderRadius = FocusTheme.defaultBorderRadius,
    required Widget child,
  }) {
    final duration = FocusTheme.getAnimationDuration(context);
    // Only show focus effects during keyboard/d-pad navigation
    final showFocus = isFocused && InputModeTracker.isKeyboardMode(context);

    final focusedWidget = AnimatedScale(
      scale: showFocus ? FocusTheme.focusScale : 1.0,
      duration: duration,
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.easeOutCubic,
        decoration: FocusTheme.focusDecoration(context, isFocused: showFocus, borderRadius: borderRadius),
        child: child,
      ),
    );

    // Wrap in GestureDetector if tap/long press handlers provided
    final gestureWidget = (onTap != null || onLongPress != null)
        ? GestureDetector(onTap: onTap, onLongPress: onLongPress, child: focusedWidget)
        : focusedWidget;

    // Wrap in Focus if focus node and key event handler provided
    if (focusNode != null && onKeyEvent != null) {
      return Focus(focusNode: focusNode, onKeyEvent: onKeyEvent, child: gestureWidget);
    }

    return gestureWidget;
  }

  /// Builds a simple locked wrapper (no Focus widget) with scale and border decoration.
  ///
  /// Used by _LockedHubItemWrapper where focus is managed at a higher level.
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
    required Widget child,
  }) {
    return buildFocusableCard(
      context: context,
      focusNode: null,
      isFocused: isFocused,
      onKeyEvent: null,
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: borderRadius,
      child: child,
    );
  }
}
