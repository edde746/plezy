import 'package:flutter/material.dart';

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
class AppBarBackButton extends StatelessWidget {
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

  void _handlePressed(BuildContext context) {
    if (onPressed != null) {
      onPressed!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case BackButtonStyle.circular:
        return _buildCircularBackButton(context);
      case BackButtonStyle.plain:
        return _buildPlainBackButton(context);
      case BackButtonStyle.video:
        return _buildVideoBackButton(context);
    }
  }

  /// Builds a back button with circular semi-transparent background
  Widget _buildCircularBackButton(BuildContext context) {
    return SafeArea(
      child: GestureDetector(
        onTap: () => _handlePressed(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.arrow_back,
            color: color ?? Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  /// Builds a plain back button without background
  Widget _buildPlainBackButton(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: color),
      onPressed: () => _handlePressed(context),
      tooltip: 'Back',
    );
  }

  /// Builds a back button styled for video player overlay
  Widget _buildVideoBackButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: IconButton(
        icon: Icon(Icons.arrow_back, color: color ?? Colors.white),
        onPressed: () => _handlePressed(context),
        tooltip: 'Back',
      ),
    );
  }
}
