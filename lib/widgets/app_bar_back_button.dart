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

class _AppBarBackButtonState extends State<AppBarBackButton> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 150), vsync: this);
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onHoverChange(bool isHovered) {
    if (isHovered) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _handlePressed() {
    if (widget.onPressed != null) {
      widget.onPressed!();
    } else {
      Navigator.of(context).pop();
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode _, KeyEvent event) {
    if (event.logicalKey != LogicalKeyboardKey.space) return KeyEventResult.ignored;
    if (event is KeyDownEvent) _handlePressed();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;

    final Color effectiveColor;
    switch (widget.style) {
      case BackButtonStyle.plain:
        effectiveColor = widget.color ?? (isDarkTheme ? Colors.white : Colors.black);
        break;
      case BackButtonStyle.circular:
      case BackButtonStyle.video:
        effectiveColor = widget.color ?? Colors.white;
        break;
    }

    final Color baseColor;
    final Color hoverColor;
    switch (widget.style) {
      case BackButtonStyle.circular:
        baseColor = Colors.black.withValues(alpha: 0.3);
        hoverColor = Colors.black.withValues(alpha: 0.5);
        break;
      case BackButtonStyle.plain:
        hoverColor = (isDarkTheme ? Colors.white : Colors.black).withValues(alpha: 0.2);
        baseColor = Colors.transparent;
        break;
      case BackButtonStyle.video:
        baseColor = Colors.transparent;
        hoverColor = Colors.black.withValues(alpha: 0.3);
        break;
    }

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
          onEnter: (_) => _onHoverChange(true),
          onExit: (_) => _onHoverChange(false),
          child: GestureDetector(
            excludeFromSemantics: true,
            onTap: _handlePressed,
            child: AnimatedBuilder(
              animation: _backgroundAnimation,
              builder: (context, child) {
                final currentColor = Color.lerp(baseColor, hoverColor, _backgroundAnimation.value);

                return Container(
                  margin: const EdgeInsets.all(8),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: currentColor, shape: BoxShape.circle),
                  child: AppIcon(Symbols.arrow_back_rounded, fill: 1, color: effectiveColor, size: 20),
                );
              },
            ),
          ),
        ),
      ),
    );

    return widget.style == BackButtonStyle.circular ? SafeArea(child: button) : button;
  }
}
