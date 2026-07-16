import 'package:flutter/material.dart';

import '../focus/dpad_navigator.dart';
import '../focus/key_event_utils.dart';
import 'bottom_sheet_header.dart';

/// Shared page layout for bottom sheets with a stable header and content area.
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
  final bool shrinkWrap;

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
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      mainAxisSize: shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
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
        if (shrinkWrap) child else Expanded(child: child),
      ],
    );

    // Let sub-pages consume Back and return to their parent instead of closing
    // the whole sheet via the overlay host.
    final back = onBack;
    if (back != null) {
      content = Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (node, event) {
          if (event.logicalKey.isBackKey) {
            return handleBackKeyAction(event, back);
          }
          return KeyEventResult.ignored;
        },
        child: content,
      );
    }

    return content;
  }
}
