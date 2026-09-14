import 'dart:async';

/// How long an open gets to produce a first frame after the server starts
/// answering the stream with HTTP 503 before the failure is surfaced.
///
/// ffmpeg's reconnect loop retries 503 with exponential backoff (0s, 1s, 3s,
/// 7s, ...), so this window covers several attempts — enough for the short
/// server restart #1520 rides out mid-stream, while a server still refusing
/// after all of them is treated as down for this item (#1830).
const Duration openHttp503Patience = Duration(seconds: 20);

/// Bounds a media open the server answers with HTTP 503.
///
/// Mid-stream, ffmpeg deliberately reconnects on 503 forever (#1520) and mpv
/// just reports buffering. At open time — before any frame has rendered —
/// that same loop is a silent black screen with no error event (#1830):
/// nothing client-side ever fails. This watchdog arms on the first 503
/// observed while the open is still frameless and calls [onPersistent] if
/// [disarm] has not been called within [patience].
///
/// The caller decides which opens are eligible (live TV stays out — its
/// fallback ladder owns retries there) and owns the synthesized error. Only
/// the timer bookkeeping lives here so it is testable with `fakeAsync`.
class OpenHttp503Watchdog {
  OpenHttp503Watchdog({required this.onPersistent, this.patience = openHttp503Patience});

  final Duration patience;
  final void Function() onPersistent;

  Timer? _timer;

  bool get isArmed => _timer != null;

  /// A 503 was observed while the current open has no frame yet. Arms once;
  /// later 503s from the same reconnect loop keep the original deadline.
  void onOpenPhase503() {
    _timer ??= Timer(patience, _fire);
  }

  /// The open produced output, was replaced, or the screen is going away:
  /// any further 503s belong to the reconnect path (or the next open).
  void disarm() {
    _timer?.cancel();
    _timer = null;
  }

  void _fire() {
    _timer = null;
    onPersistent();
  }
}
