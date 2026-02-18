import 'package:flutter/material.dart';

import '../../../focus/key_event_utils.dart';
import '../../../focus/dpad_navigator.dart';
import 'video_sheet_header.dart';

/// Base class for video control bottom sheets providing common UI structure
class BaseVideoControlSheet extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Color? iconColor;
  final VoidCallback? onBack;

  const BaseVideoControlSheet({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.iconColor,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      children: [
        VideoSheetHeader(title: title, icon: icon, iconColor: iconColor, onBack: onBack),
        const Divider(color: Colors.white24, height: 1),
        Expanded(child: child),
      ],
    );

    // Intercept back key at the sub-page level so it triggers onBack
    // instead of bubbling up to OverlaySheetHost which would close the sheet.
    if (onBack != null) {
      content = Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (node, event) {
          if (event.logicalKey.isBackKey) {
            return handleBackKeyAction(event, onBack!);
          }
          return KeyEventResult.ignored;
        },
        child: content,
      );
    }

    return SafeArea(
      child: SizedBox(height: MediaQuery.of(context).size.height * 0.75, child: content),
    );
  }
}
