import 'package:flutter/material.dart';

/// Manages a map of grid-item [FocusNode]s with focus-tracking and restoration.
///
/// Provides:
/// - Lazy creation of per-index focus nodes via [getGridItemFocusNode].
/// - Focus tracking ([lastFocusedGridIndex], [gridContentVersion]) so callers
///   can restore focus after rebuilds.
/// - [remapGridFocus] to carry focus with an item a content shift moved.
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

  void trackGridItemFocus(int index, bool hasFocus) {
    if (hasFocus) {
      lastFocusedGridIndex = index;
      lastFocusedGridContentVersion = gridContentVersion;
    }
  }

  /// Carry the highlight pinned to [oldIndex] over to [newIndex] after a
  /// content shift moved the focused item.
  ///
  /// Grid focus nodes are keyed by index, so they pin the highlight to a slot
  /// rather than to an item: a merge or re-sort that moves the focused item
  /// leaves the highlight on a slot that now renders a different title, and
  /// Select opens the wrong one. Callers that compensate other index-pinned
  /// view state for the same shift (a scroll offset) must remap focus with it.
  ///
  /// [nodeFor] resolves a slot's node the way the caller's grid does, so a
  /// remap onto or off index 0 lands on any dedicated first-item node (see
  /// [focusNodeForIndex]). No-ops when the index did not move, when the item
  /// is gone, or when the highlight is not the old slot's — an ordinary
  /// refresh must never pull focus into the grid.
  void remapGridFocus({
    required int? oldIndex,
    required int? newIndex,
    required FocusNode Function(int index) nodeFor,
  }) {
    if (oldIndex == null || newIndex == null || oldIndex == newIndex) return;
    // The index to restore to follows the item even when the highlight itself
    // is elsewhere, otherwise re-entering the grid lands on a different title.
    if (lastFocusedGridIndex == oldIndex) {
      lastFocusedGridIndex = newIndex;
      lastFocusedGridContentVersion = gridContentVersion;
    }
    // A slot that never got a node can hold no highlight; index 0 may keep
    // its node outside the map, so it always has to be asked.
    if (oldIndex != 0 && !gridItemFocusNodes.containsKey(oldIndex)) return;
    final parked = nodeFor(oldIndex);
    // Focused, or the scope's remembered child while a sheet or route holds
    // focus — a restore would come back to this very node.
    if (!parked.hasFocus && parked.enclosingScope?.focusedChild != parked) return;
    // The request waits for the rebuild that applies the shift: until then the
    // card at [newIndex] still holds that slot's node, and the detach it does
    // on being handed a different one cancels any pending request for it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Authoritative check: a key press, a cleared grid or a route change may
      // have moved the highlight on its own by now.
      if (!mounted || !parked.hasFocus) return;
      nodeFor(newIndex).requestFocus();
    });
  }

  /// Whether the last-focused index is still valid for restoration.
  bool get shouldRestoreGridFocus =>
      lastFocusedGridIndex != null && lastFocusedGridContentVersion == gridContentVersion && lastFocusedGridIndex! >= 0;

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
      final node = gridItemFocusNodes[key];
      // A focused node is still borrowed by its mounted card. Keep ownership
      // and indexed identity until a later eviction or final teardown.
      if (node == null || node.hasFocus) continue;
      gridItemFocusNodes.remove(key);
      node.dispose();
    }
  }

  void disposeGridFocusNodes() {
    for (final node in gridItemFocusNodes.values) {
      node.dispose();
    }
    gridItemFocusNodes.clear();
  }
}
