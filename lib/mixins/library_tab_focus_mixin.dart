import 'package:flutter/material.dart';

/// Mixin that provides focus management for library tabs.
/// Handles the lifecycle of a focus node for the first item and provides
/// a method to request focus on that item.
mixin LibraryTabFocusMixin<T extends StatefulWidget> on State<T> {
  /// Focus node for the first item (for programmatic focus)
  late final FocusNode firstItemFocusNode;

  /// Debug label for the focus node
  String get focusNodeDebugLabel;

  /// Number of items in the list/grid
  int get itemCount;

  @override
  void initState() {
    super.initState();
    firstItemFocusNode = FocusNode(debugLabel: focusNodeDebugLabel);
  }

  @override
  void dispose() {
    firstItemFocusNode.dispose();
    super.dispose();
  }

  /// Focus the first item in the grid/list (for tab activation)
  void focusFirstItem() {
    if (itemCount > 0) {
      firstItemFocusNode.requestFocus();
    }
  }
}
