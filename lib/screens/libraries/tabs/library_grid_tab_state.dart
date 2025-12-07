import 'package:flutter/material.dart';

import '../adaptive_media_grid.dart';
import '../../../mixins/library_tab_focus_mixin.dart';
import 'base_library_tab.dart';

/// Shared state implementation for simple grid-based library tabs.
///
/// Handles focus, item counting, and grid wiring so individual tabs only
/// implement data loading and per-item rendering.
abstract class LibraryGridTabState<T, W extends BaseLibraryTab<T>>
    extends BaseLibraryTabState<T, W>
    with LibraryTabFocusMixin {
  /// Build a single grid item.
  Widget buildGridItem(BuildContext context, T item, int index);

  @override
  int get itemCount => items.length;

  @override
  Widget buildContent(List<T> items) {
    return AdaptiveMediaGrid<T>(
      items: items,
      itemBuilder: (context, item, index) =>
          buildGridItem(context, item, index),
      onRefresh: loadItems,
      firstItemFocusNode: firstItemFocusNode,
      onBack: widget.onBack,
    );
  }
}
