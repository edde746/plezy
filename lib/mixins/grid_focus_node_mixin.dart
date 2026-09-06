import 'package:flutter/material.dart';

/// A detached FocusNode retains its last context, even after that host unmounts.
/// Keep the attachment token so eviction can distinguish history from borrowers.
class _GridFocusNode extends FocusNode {
  _GridFocusNode({super.debugLabel});

  FocusAttachment? _gridAttachment;
  bool _hasPendingFocusRequest = false;

  bool get _isAttached => _gridAttachment?.isAttached ?? false;

  @override
  FocusAttachment attach(
    BuildContext? context, {
    FocusOnKeyEventCallback? onKeyEvent,
    // ignore: deprecated_member_use
    FocusOnKeyCallback? onKey,
  }) {
    // Forward the legacy argument because this still implements FocusNode.attach.
    // ignore: deprecated_member_use
    final attachment = super.attach(context, onKeyEvent: onKeyEvent, onKey: onKey);
    _gridAttachment = attachment;
    _hasPendingFocusRequest = false;
    return attachment;
  }

  @override
  void requestFocus([FocusNode? node]) {
    if (node == null && !_isAttached && parent == null && canRequestFocus) {
      _hasPendingFocusRequest = true;
    }
    super.requestFocus(node);
  }

  @override
  void dispose() {
    _hasPendingFocusRequest = false;
    super.dispose();
    _gridAttachment = null;
  }
}

/// Owns grid nodes independently of their current spatial index. A content
/// commit reconciles every realized item's node, including scope history and
/// references captured by menus; it never requests focus behind a cover.
mixin GridFocusNodeMixin<T extends StatefulWidget> on State<T> {
  final Map<int, FocusNode> gridItemFocusNodes = {};
  final Map<int, Object> _gridItemIdentities = {};
  final Set<FocusNode> _retiredGridFocusNodes = {};
  bool _gridRetirementScheduled = false;
  int? lastFocusedGridIndex;
  int gridContentVersion = 0;
  int lastFocusedGridContentVersion = 0;

  FocusNode getGridItemFocusNode(int index, {String prefix = 'grid_item', String? debugLabel}) {
    return gridItemFocusNodes.putIfAbsent(index, () => _GridFocusNode(debugLabel: debugLabel ?? '${prefix}_$index'));
  }

  /// [firstNode] must resolve the current index-zero node owned by this mixin,
  /// not a permanently slot-bound node owned by the caller.
  FocusNode focusNodeForIndex(int index, FocusNode firstNode, {required String prefix, Object? itemIdentity}) {
    if (itemIdentity != null) _gridItemIdentities[index] = itemIdentity;
    return index == 0 ? firstNode : getGridItemFocusNode(index, prefix: prefix);
  }

  void trackGridItemFocus(int index, bool hasFocus) {
    if (hasFocus) {
      lastFocusedGridIndex = index;
      lastFocusedGridContentVersion = gridContentVersion;
    }
  }

  /// Atomically reassign spatial indices after an accepted content commit.
  /// Surviving items keep the same node and attachment. Removed items retire
  /// after their cards unmount, so captured references cannot focus a new item.
  void reconcileGridFocusNodes(Map<Object, int> indices) {
    final nodes = <int, FocusNode>{};
    final identities = <int, Object>{};
    final rememberedIndex = lastFocusedGridIndex;
    int? restoredIndex;
    for (final entry in gridItemFocusNodes.entries) {
      final identity = _gridItemIdentities[entry.key];
      final index = identity == null ? null : indices[identity];
      if (index == null) {
        _retireGridFocusNode(entry.value);
      } else {
        nodes[index] = entry.value;
        identities[index] = identity!;
        if (entry.key == rememberedIndex) restoredIndex = index;
      }
    }
    gridItemFocusNodes
      ..clear()
      ..addAll(nodes);
    _gridItemIdentities
      ..clear()
      ..addAll(identities);
    lastFocusedGridIndex = restoredIndex;
    lastFocusedGridContentVersion = gridContentVersion;
  }

  bool get shouldRestoreGridFocus =>
      lastFocusedGridIndex != null && lastFocusedGridContentVersion == gridContentVersion && lastFocusedGridIndex! >= 0;

  void _retireGridFocusNode(FocusNode node) {
    // Disable stale menu/route destinations immediately, without issuing a
    // replacement request. The owning scope supplies its normal fallback.
    node.canRequestFocus = false;
    if (node is _GridFocusNode) node._hasPendingFocusRequest = false;
    _retiredGridFocusNodes.add(node);
    if (_gridRetirementScheduled) return;
    _gridRetirementScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _gridRetirementScheduled = false;
      while (_retiredGridFocusNodes.isNotEmpty) {
        final retired = _retiredGridFocusNodes.first;
        _retiredGridFocusNodes.remove(retired);
        retired.dispose();
      }
    });
  }

  void cleanupGridFocusNodes(int itemCount) {
    final keysToRemove = gridItemFocusNodes.keys.where((i) => i >= itemCount).toList();
    for (final key in keysToRemove) {
      _retireGridFocusNode(gridItemFocusNodes.remove(key)!);
      _gridItemIdentities.remove(key);
    }
    if (lastFocusedGridIndex != null && lastFocusedGridIndex! >= itemCount) lastFocusedGridIndex = null;
  }

  /// Evict detached nodes far from the viewport, never live attachments or
  /// remembered/pending destinations. The budget is soft while those survive.
  void evictDistantFocusNodes(int centerIndex, {int keepCount = 200}) {
    if (gridItemFocusNodes.length <= keepCount) return;
    final halfKeep = keepCount ~/ 2;
    final keepStart = centerIndex - halfKeep;
    final keepEnd = centerIndex + halfKeep;
    final keysToRemove = <int>[];
    for (final entry in gridItemFocusNodes.entries) {
      final node = entry.value;
      if ((entry.key < keepStart || entry.key > keepEnd) &&
          node is _GridFocusNode &&
          !node._isAttached &&
          !node._hasPendingFocusRequest &&
          !(shouldRestoreGridFocus && entry.key == lastFocusedGridIndex) &&
          !node.hasFocus &&
          node.enclosingScope?.focusedChild != node) {
        keysToRemove.add(entry.key);
      }
    }
    for (final key in keysToRemove) {
      _retireGridFocusNode(gridItemFocusNodes.remove(key)!);
      _gridItemIdentities.remove(key);
    }
  }

  void disposeGridFocusNodes() {
    for (final node in gridItemFocusNodes.values) {
      node.dispose();
    }
    for (final node in _retiredGridFocusNodes) {
      node.dispose();
    }
    gridItemFocusNodes.clear();
    _gridItemIdentities.clear();
    _retiredGridFocusNodes.clear();
  }
}
