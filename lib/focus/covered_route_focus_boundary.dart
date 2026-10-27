import 'package:flutter/widgets.dart';

/// Keeps a subtree from taking focus while the [ModalRoute] it lives in is
/// covered by another route, and hands focus back when it is uncovered.
///
/// Flutter only marks a covered route's scope `skipTraversal`; any descendant
/// may still call `requestFocus()` and win. That is harmless on a single
/// navigator, where every screen's `ModalRoute.of(context).isCurrent` guard
/// tells the truth. It breaks with a nested navigator: a route pushed on the
/// *root* navigator (the profile picker, the PIN dialog) covers the whole
/// nested stack, yet each nested route still reports `isCurrent == true` and
/// its focus self-heals — sidebar reveal, library grid load, TV browse rail —
/// yank the remote off the visible route, which on tvOS reads as a dead
/// remote (#2034, #2239).
///
/// The boundary restores the invariant once, at the navigator boundary,
/// instead of at every reclaim site: while the enclosing route is not current
/// the subtree is [ExcludeFocus]ed, so every `requestFocus()` below it is a
/// no-op. Flutter's own restoration cannot hand focus back on uncover, because
/// the covering route's pop culls the excluded scope from the route scope's
/// history before the exclusion lifts.
///
/// So the boundary records the focus path below it when the cover begins and,
/// on uncover, refocuses the deepest part of that path still in the tree: the
/// leaf itself, or else its nearest surviving scope, whose history leads to
/// that scope's previous focus. The subtree's own scope history is not enough.
/// A sheet or menu completes its result in the frame that unmounts it, so a
/// cover pushed from that result begins while focus is still on the dying
/// item. Its detach then walks up through the now-excluded scopes, dropping
/// each from its parent's history, and the boundary's scope is left with
/// nothing to restore: focus parked above every screen key handler, and the
/// remote went dead behind the closed profile picker (#2699).
///
/// A subtree mounted under the cover has no such path. Choosing another
/// profile in the picker remounts the whole session beneath it, and the new
/// session's first focus request was dropped like any other, leaving nothing
/// to restore and the same dead remote (#2817). A request that gives a
/// subtree its *first* focus therefore goes through [requestInitialFocus],
/// which holds it while covered and replays it on uncover; every other
/// request stays a plain `requestFocus()` that the cover drops.
class CoveredRouteFocusBoundary extends StatefulWidget {
  const CoveredRouteFocusBoundary({super.key, required this.child});

  final Widget child;

  /// Requests focus for [node] as the first focus of the subtree below
  /// [context]: a screen's entry focus after it mounts or first loads.
  ///
  /// Outside a covered boundary this is `node.requestFocus()`. Under one, the
  /// request is held instead of dropped and replayed after the uncover
  /// restore, in request order, so focus ends where it would have without the
  /// cover — a scope requested after one of its descendants still lands on
  /// that descendant. A self-heal that re-takes focus keeps calling
  /// `requestFocus()` directly, so the cover still drops it.
  static void requestInitialFocus(BuildContext context, FocusNode node) {
    final boundary = context.findAncestorStateOfType<_CoveredRouteFocusBoundaryState>();
    // `_covered` is the exclusion in force, which outlives the route's own
    // currency until the next frame: a request between a pop and that frame
    // would still be dropped.
    if (boundary == null || !boundary._covered) {
      node.requestFocus();
      return;
    }
    boundary._heldRequests
      ..remove(node)
      ..add(node);
  }

  @override
  State<CoveredRouteFocusBoundary> createState() => _CoveredRouteFocusBoundaryState();
}

class _CoveredRouteFocusBoundaryState extends State<CoveredRouteFocusBoundary> {
  final _scope = FocusScopeNode(debugLabel: 'CoveredRouteFocusBoundary');
  bool _covered = false;

  /// The primary focus and its ancestors below [_scope], deepest first, as
  /// they stood when the cover began. Empty when focus was outside the subtree.
  List<FocusNode> _focusPathAtCover = const [];

  /// [CoveredRouteFocusBoundary.requestInitialFocus] calls made while
  /// covered, oldest first.
  final _heldRequests = <FocusNode>[];

  @override
  void dispose() {
    _scope.dispose();
    super.dispose();
  }

  List<FocusNode> _focusPathBelowScope() {
    if (!_scope.hasFocus) return const [];
    return [
      for (FocusNode? node = FocusManager.instance.primaryFocus; node != null && node != _scope; node = node.parent)
        node,
    ];
  }

  /// Walks [FocusNode.parent] rather than the cached `ancestors`, which can
  /// still list [_scope] for a node whose subtree has since been detached.
  bool _isAttachedBelowScope(FocusNode node) {
    for (FocusNode? ancestor = node.parent; ancestor != null; ancestor = ancestor.parent) {
      if (identical(ancestor, _scope)) return true;
    }
    return false;
  }

  /// The recorded leaf if it survived the cover, else the deepest recorded
  /// scope that did — never an intermediate non-scope node, which would park
  /// focus on a bare wrapper — else [_scope] itself.
  FocusNode _restoreTarget(List<FocusNode> path) {
    for (final node in path) {
      if (!identical(node, path.first) && node is! FocusScopeNode) continue;
      if (_isAttachedBelowScope(node) && node.canRequestFocus) return node;
    }
    return _scope;
  }

  @override
  Widget build(BuildContext context) {
    // ModalRoute.of subscribes to the route's status, so this rebuilds on
    // every isCurrent flip. Outside any route the subtree is never covered.
    final covered = !(ModalRoute.of(context)?.isCurrent ?? true);
    if (!_covered && covered) {
      // This build runs before any descendant rebuilt in the same frame can
      // unmount the focused node, so the path is still whole here.
      _focusPathAtCover = _focusPathBelowScope();
    } else if (_covered && !covered) {
      final path = _focusPathAtCover;
      _focusPathAtCover = const [];
      // The exclusion lifts in this build's didUpdateWidget, after the pop
      // already parked focus on the route scope; restore once it has, then
      // replay what the subtree asked for while covered.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!_scope.hasFocus) _restoreTarget(path).requestFocus();
        final held = List.of(_heldRequests);
        _heldRequests.clear();
        for (final node in held) {
          if (_isAttachedBelowScope(node)) node.requestFocus();
        }
      });
    }
    _covered = covered;
    return ExcludeFocus(
      excluding: covered,
      child: FocusScope(node: _scope, child: widget.child),
    );
  }
}
