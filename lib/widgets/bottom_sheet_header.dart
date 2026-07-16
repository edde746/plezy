import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'overlay_sheet.dart';

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
  /// Defaults to closing the nearest hosted sheet, with modal-route fallback.
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
    final usesBackButton = leading == null && onBack != null;

    // Determine the leading widget based on priority: leading > onBack > icon
    Widget? resolvedLeading;
    if (leading != null) {
      resolvedLeading = leading;
    } else if (onBack != null) {
      resolvedLeading = SizedBox(
        width: 24,
        height: kMinInteractiveDimension,
        child: Align(
          alignment: Alignment.centerLeft,
          child: ExcludeSemantics(child: AppIcon(Symbols.arrow_back_rounded, fill: 1, color: iconColor)),
        ),
      );
    } else if (icon != null) {
      resolvedLeading = AppIcon(icon!, fill: 1, color: iconColor);
    }

    final effectiveTitleStyle = titleStyle ?? TextStyle(fontSize: 18, fontWeight: .bold, color: titleColor);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: showBorder
          ? BoxDecoration(
              border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
            )
          : null,
      child: Stack(
        children: [
          Row(
            children: [
              if (resolvedLeading != null) ...[resolvedLeading, const SizedBox(width: 8)],
              Expanded(child: Text(title, style: effectiveTitleStyle)),
              ?action,
              ExcludeFocusTraversal(
                child: IconButton(
                  focusNode: closeFocusNode,
                  icon: AppIcon(Symbols.close_rounded, fill: 1, color: iconColor),
                  onPressed: onClose ?? () => OverlaySheetController.closeAdaptive(context),
                ),
              ),
            ],
          ),
          if (usesBackButton)
            PositionedDirectional(
              start: 0,
              top: 0,
              bottom: 0,
              width: kMinInteractiveDimension,
              child: ExcludeFocusTraversal(
                child: Semantics(
                  label: MaterialLocalizations.of(context).backButtonTooltip,
                  button: true,
                  child: InkResponse(
                    onTap: onBack,
                    radius: kMinInteractiveDimension / 2,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
