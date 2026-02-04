import 'package:flutter/material.dart';

/// Manages a map of grid-item [FocusNode]s with focus-tracking and restoration.
///
/// Provides:
/// - Lazy creation of per-index focus nodes via [getGridItemFocusNode].
/// - Focus tracking ([lastFocusedGridIndex], [gridContentVersion]) so callers
///   can restore focus after rebuilds.
/// - [cleanupGridFocusNodes] to prune nodes for indices beyond the current count.
/// - [disposeGridFocusNodes] for full teardown.
mixin GridFocusNodeMixin<T extends StatefulWidget> on State<T> {
  final Map<int, FocusNode> gridItemFocusNodes = {};
  int? lastFocusedGridIndex;
  int gridContentVersion = 0;
  int lastFocusedGridContentVersion = 0;

  /// Get or create a focus node for a grid item at [index].
  FocusNode getGridItemFocusNode(int index, {String prefix = 'grid_item'}) {
    return gridItemFocusNodes.putIfAbsent(index, () => FocusNode(debugLabel: '${prefix}_$index'));
  }

  /// Record that the item at [index] received focus.
  void trackGridItemFocus(int index, bool hasFocus) {
    if (hasFocus) {
      lastFocusedGridIndex = index;
      lastFocusedGridContentVersion = gridContentVersion;
    }
  }

  /// Whether the last-focused index is still valid for restoration.
  bool get shouldRestoreGridFocus =>
      lastFocusedGridIndex != null && lastFocusedGridContentVersion == gridContentVersion && lastFocusedGridIndex! >= 0;

  /// Remove focus nodes for indices >= [itemCount].
  void cleanupGridFocusNodes(int itemCount) {
    final keysToRemove = gridItemFocusNodes.keys.where((i) => i >= itemCount).toList();
    for (final key in keysToRemove) {
      gridItemFocusNodes[key]?.dispose();
      gridItemFocusNodes.remove(key);
    }
  }

  /// Dispose all grid-item focus nodes.
  void disposeGridFocusNodes() {
    for (final node in gridItemFocusNodes.values) {
      node.dispose();
    }
    gridItemFocusNodes.clear();
  }
}
