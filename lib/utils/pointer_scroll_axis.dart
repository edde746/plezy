import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'semantics_tree_gate.dart';

/// Collapses a diagonal scroll signal onto the axis the viewer actually moved.
///
/// A wheel, trackpoint, trackball or button-scroll event expresses one-axis
/// intent, but the host can report both axes in the same event: on Linux only
/// touchpad-sourced scrolling becomes a pan/zoom sequence (which resolves in the
/// gesture arena), while wheel/continuous/tilt sources arrive as a single
/// [PointerScrollEvent] carrying whatever `dx` the device produced. A trackball
/// or libinput button-scrolling maps pointer motion straight onto both axes, so
/// `dx` is essentially never zero there.
///
/// That matters because [Scrollable] claims a scroll signal as soon as the delta
/// along *its own* axis is non-zero, and the deepest claimant wins the
/// [PointerSignalResolver]. One pixel of `dx` therefore hands the whole event to
/// a horizontal hub row and the page behind it never scrolls — the Home,
/// library Recommended and media-detail freeze reported in #2081, on exactly the
/// screens whose viewport is covered by horizontal rows.
///
/// Returns [event] unchanged when it is already single-axis, so the common wheel
/// path allocates nothing.
PointerScrollEvent lockScrollSignalToDominantAxis(PointerScrollEvent event) {
  final Offset delta = event.scrollDelta;
  if (delta.dx == 0.0 || delta.dy == 0.0) return event;
  // Ties go to the vertical axis: pages scroll vertically, rows are the nested
  // exception, so an ambiguous event should reach the page.
  final Offset dominant = delta.dx.abs() > delta.dy.abs() ? Offset(delta.dx, 0.0) : Offset(0.0, delta.dy);
  return PointerScrollEvent(
    viewId: event.viewId,
    timeStamp: event.timeStamp,
    kind: event.kind,
    device: event.device,
    position: event.position,
    scrollDelta: dominant,
    embedderId: event.embedderId,
    onRespond: event.respond,
  );
}

/// Applies [lockScrollSignalToDominantAxis] to every scroll signal before it is
/// hit-tested, which is the only place the delta can still be corrected: by the
/// time a [Scrollable] sees the event it has already registered with the
/// [PointerSignalResolver], and only the first (deepest) registration runs.
///
/// Pan/zoom events are left alone — trackpad panning is resolved by the gesture
/// arena, which already prefers the axis the viewer moved along.
mixin PointerScrollAxisLock on GestureBinding {
  @override
  void handlePointerEvent(PointerEvent event) {
    super.handlePointerEvent(event is PointerScrollEvent ? lockScrollSignalToDominantAxis(event) : event);
  }
}

/// The app's binding: installs [PointerScrollAxisLock] and [SemanticsTreeGate].
class PlezyWidgetsBinding extends WidgetsFlutterBinding with PointerScrollAxisLock, SemanticsTreeGate {
  static bool _initialized = false;

  /// Creates the binding on first call and returns it afterwards, mirroring
  /// [WidgetsFlutterBinding.ensureInitialized].
  static WidgetsBinding ensureInitialized() {
    if (!_initialized) {
      PlezyWidgetsBinding();
      _initialized = true;
    }
    return WidgetsBinding.instance;
  }
}
