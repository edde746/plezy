import 'package:flutter/foundation.dart';

/// Snapshot of both first-frame flags, taken before an in-place reload or a
/// live channel zap so a failed replacement can restore the outgoing
/// stream's readiness state transactionally.
typedef FirstFrameSnapshot = ({bool uiReady, bool rendered});

/// The player screen's first-frame readiness state, in one place.
///
/// Two deliberately asymmetric flags:
/// - [uiReady] drives the UI (spinner, chrome, controls readiness). It may be
///   forced true after a startup failure purely to hide the loading spinner.
/// - [rendered] is the stricter reporting latch: only a renderer event (or
///   the established non-ExoPlayer position fallback) marks it, and progress
///   reporting/watchdog gating read it.
///
/// The [uiReady] notifier is created once per screen and must keep its
/// identity across playback attempts, reloads, and channel zaps — the video
/// surface, controls, and buffering overlay hold it by reference.
class FirstFrameGate {
  final ValueNotifier<bool> uiReady = ValueNotifier<bool>(false);
  bool _rendered = false;

  bool get rendered => _rendered;

  /// A frame is on screen: latch reporting readiness and unblock the UI.
  void markReady() {
    _rendered = true;
    uiReady.value = true;
  }

  /// A new open is about to produce its own first frame; show the spinner.
  void resetUiForOpen() {
    uiReady.value = false;
  }

  /// A new playback attempt owns the reporting latch from here on.
  void resetRenderedForAttempt() {
    _rendered = false;
  }

  /// Full reset — attempt teardown and live channel zaps.
  void reset() {
    uiReady.value = false;
    _rendered = false;
  }

  /// Hide the spinner after a startup failure WITHOUT latching rendered:
  /// UI readiness and reporting readiness intentionally diverge here.
  void forceUiReadyOnFailure() {
    uiReady.value = true;
  }

  FirstFrameSnapshot snapshot() => (uiReady: uiReady.value, rendered: _rendered);

  void restore(FirstFrameSnapshot snapshot) {
    uiReady.value = snapshot.uiReady;
    _rendered = snapshot.rendered;
  }

  void dispose() {
    uiReady.dispose();
  }
}
