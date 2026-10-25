import 'package:flutter/material.dart';

import '../focus/back_press.dart';
import 'bottom_sheet_header.dart';

/// Shared page layout for bottom sheets with a stable header and content area.
///
/// The content area is a [Flexible], so the page is as tall as [child] wants to
/// be and no taller, while still being clamped by the sheet's own maximum
/// height. [child] should therefore shrink-wrap in the vertical axis: use a
/// `SingleChildScrollView`, or a list with `shrinkWrap: true`. A plain
/// scrollable sizes itself to the incoming maximum and reintroduces the empty
/// space this layout exists to avoid.
///
/// A child may deliberately fill instead when a content-driven height would
/// move a control the user is operating — sheets are bottom-anchored, so a
/// shrinking body drags the top edge and anything above the scroll area with
/// it. `SubtitleSearchSheet` and its language picker opt out for that
/// reason; document any other.
class BottomSheetPageScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? leading;
  final Widget? action;
  final VoidCallback? onClose;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onBack;
  final TextStyle? titleStyle;
  final Color? titleColor;
  final bool showHeaderBorder;
  final bool showHeaderDivider;
  final FocusNode? closeFocusNode;

  const BottomSheetPageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.leading,
    this.action,
    this.onClose,
    this.icon,
    this.iconColor,
    this.onBack,
    this.titleStyle,
    this.titleColor,
    this.showHeaderBorder = true,
    this.showHeaderDivider = false,
    this.closeFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BottomSheetHeader(
          title: title,
          leading: leading,
          action: action,
          onClose: onClose,
          icon: icon,
          iconColor: iconColor,
          onBack: onBack,
          titleStyle: titleStyle,
          titleColor: titleColor,
          showBorder: showHeaderBorder,
          closeFocusNode: closeFocusNode,
        ),
        if (showHeaderDivider) Divider(color: Theme.of(context).dividerColor, height: 1),
        Flexible(child: child),
      ],
    );

    // Let sub-pages consume Back and return to their parent instead of closing
    // the whole sheet via the overlay host.
    final back = onBack;
    if (back != null) {
      content = BackKeyOwner(onBack: back, child: content);
    }

    return content;
  }
}
