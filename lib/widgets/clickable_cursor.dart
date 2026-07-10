import 'package:flutter/material.dart';

import '../utils/platform_detector.dart';

class ClickableCursor extends StatelessWidget {
  final Widget child;
  final bool enabled;

  const ClickableCursor({super.key, required this.child, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    // Cursor feedback only matters where a pointer exists: skip the
    // MouseRegion on TV and touch handhelds — one exists per card and they
    // add up on low-end devices.
    if (!PlatformDetector.isDesktopOS()) return child;
    return MouseRegion(cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer, child: child);
  }
}
