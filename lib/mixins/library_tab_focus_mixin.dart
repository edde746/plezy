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
      revealFirstItem();
      firstItemFocusNode.requestFocus();
    }
  }

  /// Scroll this tab back to its start when the first item's card is not
  /// built. A grid scrolled past its first rows has unmounted that card, and
  /// Flutter only honors a focus request on its detached node once the node is
  /// attached again — so without this the request lands nowhere until the
  /// viewer happens to scroll back up.
  @protected
  void revealFirstItem() {
    if (firstItemFocusNode.context?.mounted ?? false) return;
    // The tab's scroll view attaches to NestedScrollView's shared inner
    // controller, which holds one position per kept-alive tab: find this one.
    final controller = PrimaryScrollController.maybeOf(context);
    if (controller == null) return;
    for (final position in controller.positions) {
      if (!_isInThisTab(position.context.storageContext)) continue;
      if (position.hasPixels && position.pixels > position.minScrollExtent) {
        position.jumpTo(position.minScrollExtent);
      }
      return;
    }
  }

  bool _isInThisTab(BuildContext descendant) {
    var found = false;
    descendant.visitAncestorElements((element) {
      found = identical(element, context);
      return !found;
    });
    return found;
  }
}
