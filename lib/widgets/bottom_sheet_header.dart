import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../i18n/strings.g.dart';

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

  final bool compact;

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
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final usesBackButton = leading == null && onBack != null;
    final controlSize = compact ? 32.0 : kMinInteractiveDimension;

    Widget? resolvedLeading;
    if (leading != null) {
      resolvedLeading = leading;
    } else if (onBack != null) {
      resolvedLeading = SizedBox(
        width: 24,
        height: controlSize,
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
      padding: EdgeInsets.symmetric(vertical: compact ? 4 : 8),
      decoration: showBorder
          ? BoxDecoration(
              border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
            )
          : null,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsetsDirectional.only(start: 16, end: compact ? 8 : 16),
            child: Row(
              children: [
                if (resolvedLeading != null) ...[resolvedLeading, const SizedBox(width: 8)],
                Expanded(child: Text(title, style: effectiveTitleStyle)),
                ?action,
                ExcludeFocusTraversal(
                  child: IconButton(
                    focusNode: closeFocusNode,
                    tooltip: t.common.close,
                    icon: AppIcon(Symbols.close_rounded, fill: 1, color: iconColor),
                    padding: compact ? EdgeInsets.zero : null,
                    constraints: compact ? BoxConstraints.tightFor(width: controlSize, height: controlSize) : null,
                    style: compact
                        ? IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            minimumSize: Size.square(controlSize),
                          )
                        : null,
                    onPressed: onClose ?? () => OverlaySheetController.closeAdaptive(context),
                  ),
                ),
              ],
            ),
          ),
          if (usesBackButton)
            PositionedDirectional(
              // Center the hit target (and thus the circular hover/press
              // highlight of the InkResponse) on the 24px arrow glyph, which
              // sits at the row's leading edge inside the 16px padding.
              start: 16 + 12 - kMinInteractiveDimension / 2,
              top: 0,
              bottom: 0,
              width: controlSize,
              child: ExcludeFocusTraversal(
                child: Semantics(
                  label: MaterialLocalizations.of(context).backButtonTooltip,
                  button: true,
                  child: InkResponse(onTap: onBack, radius: controlSize / 2, child: const SizedBox.expand()),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
