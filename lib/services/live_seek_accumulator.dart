import 'dart:async';

/// Inclusive epoch-second window a live seek may target (the capture buffer's
/// seekable range). `start` ≈ earliest seekable point, `end` ≈ the live edge.
typedef LiveSeekBounds = ({int start, int end});

/// Coalesces rapid relative live-TV skips into a single transcode re-open.
///
/// Live time-shift seeks don't use `player.seek()` — each one re-opens a fresh
/// Plex transcode session at an epoch offset, and the new stream's reported
/// position lags behind the new origin for a second or two. Deriving each skip
/// target from the live `streamStart + position` epoch therefore compounds into
/// wild overshoots when the user mashes skip-forward, occasionally jumping all
/// the way to live (#1253).
///
/// This accumulates a stable in-memory target ([pendingEpoch]) — every press
/// adds onto the previous target, never re-reading the laggy live epoch — and
/// debounces the actual re-open so a whole burst collapses into one [seek].
/// The pending target is held until the re-opened stream's position settles
/// near zero, so a subsequent idle press still bases off a correct value.
///
/// Pure-Dart and timer-driven (no wall-clock reads), so it virtualizes cleanly
/// under `fakeAsync` in tests.
class LiveSeekAccumulator {
  LiveSeekAccumulator({
    required this.seek,
    required this.currentEpoch,
    required this.positionSeconds,
    required this.bounds,
    this.onChanged,
    this.debounce = const Duration(milliseconds: 300),
    this.settleCeiling = const Duration(milliseconds: 1500),
    this.settlePoll = const Duration(milliseconds: 100),
  });

  /// Re-open the live stream at the target epoch (a fresh transcode session).
  /// Should log its own errors; if it throws, the pending pin is released so a
  /// failed re-open can't freeze the masked position.
  final Future<void> Function(int targetEpoch) seek;

  /// The live playback position as an absolute epoch second
  /// (`streamStart + position`) — used as the base for a fresh burst.
  final int Function() currentEpoch;

  /// Player position in seconds — used to detect that a re-opened stream has
  /// settled (position reset to ~0) before unpinning [pendingEpoch].
  final int Function() positionSeconds;

  /// Current seekable window, or null when there is no live capture buffer.
  final LiveSeekBounds? Function() bounds;

  /// Notified whenever [pendingEpoch] changes (so the owner can rebuild UI and
  /// recompute live-edge state).
  final void Function()? onChanged;

  /// How long after the last press to wait before executing the seek.
  final Duration debounce;

  /// Upper bound on how long [pendingEpoch] stays pinned after a re-open before
  /// it is cleared regardless of whether the position has settled.
  final Duration settleCeiling;

  /// Interval at which the post-seek settle is polled.
  final Duration settlePoll;

  int? _pendingEpoch;
  Timer? _debounceTimer;
  Timer? _settleTimer;
  bool _flushing = false;
  bool _disposed = false;

  /// The accumulated target while a skip is pending or settling, else null.
  /// Callers mask their "current position" with this so accumulation and the
  /// live-edge heartbeat stay correct across the re-open's position lag.
  int? get pendingEpoch => _pendingEpoch;

  /// Accumulate a relative skip of [deltaSeconds] and (re)arm the debounce.
  /// No-op when there is no seekable window.
  void seekBy(int deltaSeconds) {
    if (_disposed) return;
    final window = bounds();
    if (window == null) return;

    final base = _pendingEpoch ?? currentEpoch();
    final clampedBase = base.clamp(window.start, window.end);
    final target = (base + deltaSeconds).clamp(window.start, window.end);
    // Do not rebuild the stream when a relative skip is clamped back to the
    // position it already occupies (most commonly fast-forward at live edge).
    // Once a burst has a pending target, keep its normal debounce semantics.
    if (_pendingEpoch == null && target == clampedBase) return;
    if (target != _pendingEpoch) {
      _pendingEpoch = target;
      onChanged?.call();
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () => unawaited(_flush()));
  }

  Future<void> _flush() async {
    if (_flushing || _disposed) return;
    final target = _pendingEpoch;
    if (target == null) return;
    // We're committing to this seek; don't let a stale debounce double-fire it.
    _debounceTimer?.cancel();

    _flushing = true;
    var failed = false;
    try {
      await seek(target);
    } catch (_) {
      // A failed re-open must release the pin, or the masked position would
      // freeze at a target the stream never reached. `seek` is expected to log
      // its own errors; here we only guarantee forward progress.
      failed = true;
    } finally {
      _flushing = false;
    }
    if (_disposed) return;

    if (failed) {
      if (_pendingEpoch == target) {
        _pendingEpoch = null;
        onChanged?.call();
      }
      return;
    }

    // A press landed during the network round-trip + open: flush the newer
    // target immediately rather than waiting for another debounce.
    if (_pendingEpoch != target) {
      unawaited(_flush());
      return;
    }
    _scheduleClear(target);
  }

  /// Hold the pinned target until the fresh transcode's position resets to ~0
  /// (then `streamStart + position` == target and unpinning is seamless), with
  /// [settleCeiling] as a backstop in case it never settles.
  void _scheduleClear(int target) {
    _settleTimer?.cancel();
    var elapsed = Duration.zero;
    void tick() {
      if (_disposed || _pendingEpoch != target) return;
      elapsed += settlePoll;
      if (positionSeconds() < 2 || elapsed >= settleCeiling) {
        _pendingEpoch = null;
        onChanged?.call();
        return;
      }
      _settleTimer = Timer(settlePoll, tick);
    }

    _settleTimer = Timer(settlePoll, tick);
  }

  /// Drop any queued/settling seek. Used when the session is about to be
  /// replaced (channel switch, retry) or superseded by an absolute seek, so a
  /// stale debounced seek can't fire against the new stream.
  void cancel() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _settleTimer?.cancel();
    _settleTimer = null;
    _flushing = false;
    if (_pendingEpoch != null) {
      _pendingEpoch = null;
      onChanged?.call();
    }
  }

  void dispose() {
    _disposed = true;
    _debounceTimer?.cancel();
    _settleTimer?.cancel();
  }
}
