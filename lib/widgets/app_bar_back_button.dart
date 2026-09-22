import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../focus/focusable_wrapper.dart';
import '../i18n/strings.g.dart';
import 'app_icon.dart';

/// Defines the visual style of the back button
enum BackButtonStyle {
  /// Back button with circular semi-transparent background (used in detail screens)
  circular,

  /// Plain back button without background (used in sheets and simple contexts)
  plain,

  /// Back button styled for video player overlay
  video,
}

/// A reusable back button widget that provides consistent styling across the app.
///
/// This widget supports different visual styles through [BackButtonStyle] enum:
/// - [BackButtonStyle.circular]: Semi-transparent circular background for detail screens
/// - [BackButtonStyle.plain]: Simple IconButton for sheets and simple contexts
/// - [BackButtonStyle.video]: Styled for video player overlay
///
/// Example usage:
/// ```dart
/// AppBarBackButton(style: BackButtonStyle.circular)
/// ```
class AppBarBackButton extends StatefulWidget {
  /// Creates a back button with the specified style.
  ///
  /// [style] determines the visual appearance of the back button.
  /// [onPressed] is called when the button is tapped. If null, defaults to Navigator.pop.
  /// [color] overrides the default icon color. If null, uses white for circular/video, theme default for plain.
  /// [focusNode] allows callers to connect this control to an explicit focus graph.
  /// [semanticLabel] overrides the localized back-button label.
  const AppBarBackButton({
    super.key,
    this.style = BackButtonStyle.circular,
    this.onPressed,
    this.color,
    this.semanticLabel,
    this.focusNode,
  });

  final BackButtonStyle style;

  /// Callback when the button is pressed. Defaults to Navigator.of(context).pop()
  final VoidCallback? onPressed;

  /// The color of the back arrow icon. If null, uses style-appropriate default.
  final Color? color;

  final String? semanticLabel;
  final FocusNode? focusNode;

  @override
  State<AppBarBackButton> createState() => _AppBarBackButtonState();
}

class _AppBarBackButtonState extends State<AppBarBackButton> {
  bool _hovered = false;

  void _handlePressed() {
    if (widget.onPressed != null) {
      widget.onPressed!();
    } else {
      Navigator.of(context).pop();
    }
  }

  /// Space is not in the shared select-key set (Enter/Select/gamepad A), which
  /// [FocusableWrapper] already handles; this adds the plain-keyboard activation.
  KeyEventResult _handleKeyEvent(FocusNode _, KeyEvent event) {
    if (event.logicalKey != LogicalKeyboardKey.space) return KeyEventResult.ignored;
    if (event is KeyDownEvent) _handlePressed();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final onTheme = isDarkTheme ? Colors.white : Colors.black;

    final (Color icon, Color base, Color hover) = switch (widget.style) {
      BackButtonStyle.circular => (
        widget.color ?? Colors.white,
        Colors.black.withValues(alpha: 0.3),
        Colors.black.withValues(alpha: 0.5),
      ),
      BackButtonStyle.plain => (widget.color ?? onTheme, Colors.transparent, onTheme.withValues(alpha: 0.2)),
      BackButtonStyle.video => (widget.color ?? Colors.white, Colors.transparent, Colors.black.withValues(alpha: 0.3)),
    };

    final semanticLabel = widget.semanticLabel ?? t.common.back;
    final button = FocusableWrapper(
      focusNode: widget.focusNode,
      semanticLabel: semanticLabel,
      onSelect: _handlePressed,
      onKeyEvent: _handleKeyEvent,
      autoScroll: false,
      disableScale: true,
      descendantsAreFocusable: false,
      borderRadius: 20,
      child: Tooltip(
        message: semanticLabel,
        excludeFromSemantics: true,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            excludeFromSemantics: true,
            onTap: _handlePressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.all(8),
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: _hovered ? hover : base, shape: BoxShape.circle),
              child: AppIcon(Symbols.arrow_back_rounded, fill: 1, color: icon, size: 20),
            ),
          ),
        ),
      ),
    );

    return widget.style == BackButtonStyle.circular ? SafeArea(child: button) : button;
  }
}
