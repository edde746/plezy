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
/// no-op. On uncover it re-requests the subtree's own [FocusScope], whose
/// focus history still leads back to the leaf that had focus before the
/// cover; Flutter's own restoration cannot, because the covering route's pop
/// culls the excluded scope from the route scope's history before the
/// exclusion lifts.
class CoveredRouteFocusBoundary extends StatefulWidget {
  const CoveredRouteFocusBoundary({super.key, required this.child});

  final Widget child;

  @override
  State<CoveredRouteFocusBoundary> createState() => _CoveredRouteFocusBoundaryState();
}

class _CoveredRouteFocusBoundaryState extends State<CoveredRouteFocusBoundary> {
  final _scope = FocusScopeNode(debugLabel: 'CoveredRouteFocusBoundary');
  bool _covered = false;

  @override
  void dispose() {
    _scope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ModalRoute.of subscribes to the route's status, so this rebuilds on
    // every isCurrent flip. Outside any route the subtree is never covered.
    final covered = !(ModalRoute.of(context)?.isCurrent ?? true);
    if (_covered && !covered) {
      // The exclusion lifts in this build's didUpdateWidget, after the pop
      // already parked focus on the route scope; restore once it has.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_scope.hasFocus) _scope.requestFocus();
      });
    }
    _covered = covered;
    return ExcludeFocus(
      excluding: covered,
      child: FocusScope(node: _scope, child: widget.child),
    );
  }
}
