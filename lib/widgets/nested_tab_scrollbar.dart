import 'package:flutter/widgets.dart';

/// The scrollbar the ambient [ScrollBehavior] would draw (a Material
/// scrollbar on desktop, none on mobile and TV) for one tab's scroll view in a
/// [NestedScrollView] body, bound to that tab's own position.
///
/// [NestedScrollView] hands every body scroll view one shared inner
/// [PrimaryScrollController] holding a position per kept-alive tab. The
/// behavior's automatic scrollbar reads that shared controller, so it stops
/// painting and asserts as soon as a second tab has been built. A host
/// therefore turns behavior scrollbars off for its body and wraps each tab's
/// scroll view in this widget instead.
class NestedTabScrollbar extends StatefulWidget {
  const NestedTabScrollbar({super.key, this.rightInset = 0, required this.child});

  /// Width kept clear at the right edge for a control overlaid there; the
  /// scrollbar is drawn immediately inside it.
  final double rightInset;

  /// Subtree whose nearest [Scrollable] the scrollbar tracks.
  final Widget child;

  @override
  State<NestedTabScrollbar> createState() => _NestedTabScrollbarState();
}

class _NestedTabScrollbarState extends State<NestedTabScrollbar> {
  final _SinglePositionController _controller = _SinglePositionController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _handleScrollMetrics(ScrollMetricsNotification notification) {
    // A position reports its metrics after its first layout, including a
    // position the Scrollable recreates when its dependencies change (e.g. the
    // device pixel ratio), so rebinding here follows every replacement.
    if (notification.depth == 0) {
      _controller.bind(Scrollable.maybeOf(notification.context)?.position);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // The Material scrollbar insets itself by MediaQuery padding, so widen the
    // right padding for the scrollbar alone and restore it for the child.
    final mediaQuery = MediaQuery.of(context);
    final scrollbar = ScrollConfiguration.of(context)
        .copyWith(scrollbars: true)
        .buildScrollbar(
          context,
          MediaQuery(data: mediaQuery, child: widget.child),
          ScrollableDetails(direction: AxisDirection.down, controller: _controller),
        );
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: _handleScrollMetrics,
      child: MediaQuery(
        data: mediaQuery.copyWith(
          padding: mediaQuery.padding.copyWith(right: mediaQuery.padding.right + widget.rightInset),
        ),
        child: scrollbar,
      ),
    );
  }
}

/// Tracks exactly one position that a [Scrollable] elsewhere creates and
/// disposes. Detaching only removes this controller's listener.
class _SinglePositionController extends ScrollController {
  void bind(ScrollPosition? position) {
    if (positions.length == 1 && identical(positions.first, position)) return;
    for (final attached in positions.toList()) {
      detach(attached);
    }
    if (position != null) attach(position);
  }
}
