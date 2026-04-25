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

  /// Get the focus node for [index], routing index 0 through [firstNode] when
  /// the grid pins a dedicated node for the first item (e.g. `firstItemFocusNode`).
  FocusNode focusNodeForIndex(int index, FocusNode firstNode, {required String prefix}) {
    return index == 0 ? firstNode : getGridItemFocusNode(index, prefix: prefix);
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

  /// Evict focus nodes far from [centerIndex], keeping at most [keepCount] around it.
  void evictDistantFocusNodes(int centerIndex, {int keepCount = 200}) {
    if (gridItemFocusNodes.length <= keepCount) return;

    final halfKeep = keepCount ~/ 2;
    final keepStart = centerIndex - halfKeep;
    final keepEnd = centerIndex + halfKeep;

    final keysToRemove = <int>[];
    for (final key in gridItemFocusNodes.keys) {
      if (key < keepStart || key > keepEnd) {
        keysToRemove.add(key);
      }
    }
    for (final key in keysToRemove) {
      final node = gridItemFocusNodes.remove(key);
      if (node != null && !node.hasFocus) {
        node.dispose();
      }
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
