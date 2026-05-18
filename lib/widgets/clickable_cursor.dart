import 'package:flutter/material.dart';

class ClickableCursor extends StatelessWidget {
  final Widget child;
  final bool enabled;

  const ClickableCursor({super.key, required this.child, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer, child: child);
  }
}
