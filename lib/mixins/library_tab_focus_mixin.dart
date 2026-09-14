import 'package:flutter/material.dart';
import 'grid_focus_node_mixin.dart';

/// Tab-entry focus resolves the current first item's grid-owned node. Reorders
/// may move the former first node elsewhere without invalidating menu restores.
mixin LibraryTabFocusMixin<T extends StatefulWidget> on State<T>, GridFocusNodeMixin<T> {
  FocusNode get firstItemFocusNode => getGridItemFocusNode(0, debugLabel: focusNodeDebugLabel);

  String get focusNodeDebugLabel;

  int get itemCount;

  /// Focus the first item in the grid/list (for tab activation)
  void focusFirstItem() {
    if (itemCount > 0) {
      firstItemFocusNode.requestFocus();
    }
  }
}
