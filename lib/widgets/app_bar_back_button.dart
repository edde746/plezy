import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  const AppBarBackButton({
    super.key,
    this.style = BackButtonStyle.circular,
    this.onPressed,
    this.color,
  });

  /// The visual style of the back button
  final BackButtonStyle style;

  /// Callback when the button is pressed. Defaults to Navigator.of(context).pop()
  final VoidCallback? onPressed;

  /// The color of the back arrow icon. If null, uses style-appropriate default.
  final Color? color;

  @override
  State<AppBarBackButton> createState() => _AppBarBackButtonState();
}

class _AppBarBackButtonState extends State<AppBarBackButton>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;

    final Color effectiveColor;
    switch (widget.style) {
      case BackButtonStyle.plain:
        effectiveColor =
            widget.color ?? (isDarkTheme ? Colors.white : Colors.black);
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
        hoverColor = (isDarkTheme ? Colors.white : Colors.black).withValues(
          alpha: 0.2,
        );
        baseColor = Colors.transparent;
        break;
      case BackButtonStyle.video:
        baseColor = Colors.transparent;
        hoverColor = Colors.black.withValues(alpha: 0.3);
        break;
    }

    final button = Focus(
      // Make the button focusable on TV for D-pad navigation
      autofocus: false,
      onKeyEvent: (node, event) {
        // Handle D-pad center/select and Enter key
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.space)) {
          _handlePressed();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => _onHoverChange(true),
            onExit: (_) => _onHoverChange(false),
            child: GestureDetector(
              onTap: _handlePressed,
              child: AnimatedBuilder(
                animation: _backgroundAnimation,
                builder: (context, child) {
                  final currentColor = Color.lerp(
                    baseColor,
                    hoverColor,
                    _backgroundAnimation.value,
                  );

                  return Container(
                    margin: const EdgeInsets.all(8),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: currentColor,
                      shape: BoxShape.circle,
                      border: isFocused
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      color: effectiveColor,
                      size: 20,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );

    return widget.style == BackButtonStyle.circular
        ? SafeArea(child: button)
        : button;
  }
}
