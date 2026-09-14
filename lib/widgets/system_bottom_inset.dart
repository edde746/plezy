import 'package:flutter/widgets.dart';

/// Reserves the system bottom inset — Android's navigation bar, iOS's home
/// indicator — at the end of a scroll view.
///
/// Plezy always runs edge-to-edge on Android: `targetSdk` is 36, and Android
/// 15 enforces edge-to-edge for apps targeting 35+ while Android 16 removes
/// the opt-out entirely. So `MediaQuery.padding.bottom` is a real overlap on
/// phones (~48dp with 3-button navigation, less with gesture navigation) and
/// every full-screen pushed route has to consume it.
///
/// The convention is to bake the inset into the scroll *content* rather than
/// wrapping the scroll view in a [SafeArea]: content keeps painting under the
/// bar, and only the scroll extent grows so the last row can be scrolled clear
/// of it. See `media_detail_screen.dart` and `discover_screen.dart` for the
/// hand-rolled precedents this widget replaces.
///
/// Collapses to zero height wherever the bottom padding is already zero, so it
/// needs no platform branching: desktop and Android TV report no inset, tvOS
/// has it zeroed by `_FormFactorScale`, and inside `MainScreen`'s tab bodies
/// Flutter's [Scaffold] has already stripped it because a `bottomNavigationBar`
/// is present.
///
/// Reading the padding from this widget's own [BuildContext] — instead of the
/// enclosing screen's — keeps it correct below any ancestor that removes
/// padding, and limits inset-driven rebuilds to the spacer itself.
class SliverSystemBottomInset extends StatelessWidget {
  const SliverSystemBottomInset({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(padding: .only(bottom: MediaQuery.paddingOf(context).bottom));
  }
}
