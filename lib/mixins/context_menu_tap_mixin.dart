import 'package:flutter/material.dart';

import '../widgets/media_context_menu.dart';

/// Tracks tap position and exposes show-context-menu helpers for media cards
/// that wrap their tappable area in a [MediaContextMenu].
mixin ContextMenuTapMixin<T extends StatefulWidget> on State<T> {
  final GlobalKey<MediaContextMenuState> contextMenuKey = GlobalKey<MediaContextMenuState>();
  Offset? _tapPosition;

  void storeTapPosition(TapDownDetails details) {
    _tapPosition = details.globalPosition;
  }

  bool get isContextMenuOpen => contextMenuKey.currentState?.isContextMenuOpen ?? false;

  /// Show at the last tap position (long-press, mouse).
  void showContextMenuFromTap() {
    contextMenuKey.currentState?.showContextMenu(context, position: _tapPosition);
  }

  /// Show without a tap position (keyboard, gamepad).
  void showContextMenu() {
    contextMenuKey.currentState?.showContextMenu(context);
  }
}
