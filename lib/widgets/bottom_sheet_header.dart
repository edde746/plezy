import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';

/// A reusable header widget for bottom sheets
/// Provides consistent styling with title, optional leading widget, optional action, and close button
class BottomSheetHeader extends StatelessWidget {
  /// The title text to display
  final String title;

  /// Optional leading widget (e.g., icon or back button)
  /// Takes precedence over [icon] and [onBack]
  final Widget? leading;

  /// Optional action widget (e.g., clear button)
  final Widget? action;

  /// Optional callback when close button is pressed
  /// Defaults to Navigator.pop(context)
  final VoidCallback? onClose;

  /// Optional icon to display as leading widget
  /// Only used if [leading] and [onBack] are null
  final IconData? icon;

  /// Optional color for the icon
  /// Only used when [icon] is provided
  final Color? iconColor;

  /// Optional callback for back button
  /// When provided, displays a back button as the leading widget
  /// Takes precedence over [icon]
  final VoidCallback? onBack;

  /// Optional text style for the title
  final TextStyle? titleStyle;

  /// Optional text color for the title
  /// Only used if [titleStyle] is null
  final Color? titleColor;

  /// Whether to show the bottom border
  /// Defaults to true
  final bool showBorder;

  /// Optional focus node for the close button
  final FocusNode? closeFocusNode;

  const BottomSheetHeader({
    super.key,
    required this.title,
    this.leading,
    this.action,
    this.onClose,
    this.icon,
    this.iconColor,
    this.onBack,
    this.titleStyle,
    this.titleColor,
    this.showBorder = true,
    this.closeFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the leading widget based on priority: leading > onBack > icon
    Widget? resolvedLeading;
    if (leading != null) {
      resolvedLeading = leading;
    } else if (onBack != null) {
      resolvedLeading = IconButton(
        icon: AppIcon(
          Symbols.arrow_back_rounded,
          fill: 1,
          color: iconColor,
        ),
        onPressed: onBack,
      );
    } else if (icon != null) {
      resolvedLeading = AppIcon(icon!, fill: 1, color: iconColor);
    }

    // Determine the title style
    final effectiveTitleStyle = titleStyle ??
        TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: titleColor,
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: showBorder
          ? BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            )
          : null,
      child: Row(
        children: [
          if (resolvedLeading != null) ...[
            resolvedLeading,
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              style: effectiveTitleStyle,
            ),
          ),
          if (action != null) action!,
          IconButton(
            focusNode: closeFocusNode,
            icon: AppIcon(Symbols.close_rounded, fill: 1, color: iconColor),
            onPressed: onClose ?? () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
