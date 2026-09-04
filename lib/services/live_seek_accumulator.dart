import 'dart:async';

/// Inclusive epoch-second window a live seek may target (the capture buffer's
/// seekable range). `start` ≈ earliest seekable point, `end` ≈ the live edge.
typedef LiveSeekBounds = ({int start, int end});

/// Coalesces rapid relative live-TV skips into a single transcode re-open.
///
/// Live time-shift seeks don't use `player.seek()` — each one re-opens a fresh
/// Plex transcode session at an epoch offset. This accumulates a stable
/// in-memory target ([pendingEpoch]) so every press adds onto the previous
/// target rather than re-reading player state while a source replacement is
/// in flight, then debounces the actual re-open so a whole burst collapses
/// into one [seek] (#1253).
///
/// [seek] completes only after the replacement source's player clock has been
/// calibrated. The pending target therefore remains authoritative until raw
/// player position can be mapped back to epoch time without assuming that a
/// newly opened HLS source starts at position zero (#2100).
class LiveSeekAccumulator {
  LiveSeekAccumulator({
    required this.seek,
    required this.currentEpoch,
    required this.bounds,
    this.onChanged,
    this.debounce = const Duration(milliseconds: 300),
  });

  /// Re-open and calibrate the live stream at the target epoch.
  ///
  /// Returns false when URL resolution, open, or clock calibration fails.
  final Future<bool> Function(int targetEpoch) seek;

  /// The calibrated live playback position as an absolute epoch second, used
  /// as the base for a fresh burst.
  final int Function() currentEpoch;

  /// Current seekable window, or null when there is no live capture buffer.
  final LiveSeekBounds? Function() bounds;

  /// Notified whenever [pendingEpoch] changes (so the owner can rebuild UI and
  /// recompute live-edge state).
  final void Function()? onChanged;

  /// How long after the last press to wait before executing the seek.
  final Duration debounce;

  int? _pendingEpoch;
  Timer? _debounceTimer;
  bool _flushing = false;
  bool _disposed = false;
  int _operationGeneration = 0;

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
    final operationGeneration = _operationGeneration;
    var failed = false;
    try {
      failed = !await seek(target);
    } catch (_) {
      // A failed re-open must release the pin, or the masked position would
      // freeze at a target the stream never reached. `seek` is expected to log
      // its own errors; here we only guarantee forward progress.
      failed = true;
    } finally {
      if (operationGeneration == _operationGeneration) {
        _flushing = false;
      }
    }
    if (_disposed || operationGeneration != _operationGeneration) return;

    if (failed) {
      if (_pendingEpoch == target) {
        _pendingEpoch = null;
        onChanged?.call();
      }
      return;
    }

    // A press landed during the network round-trip + calibration: flush the
    // newer target immediately rather than waiting for another debounce.
    if (_pendingEpoch != target) {
      unawaited(_flush());
      return;
    }

    // `seek` returning true proves the replacement clock is calibrated, so
    // raw epoch reads are coherent and the pending target can be released.
    _pendingEpoch = null;
    onChanged?.call();
  }

  /// Drop any queued/settling seek. Used when the session is about to be
  /// replaced (channel switch, retry) or superseded by an absolute seek, so a
  /// stale debounced seek can't fire against the new stream.
  void cancel() {
    _operationGeneration++;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _flushing = false;
    if (_pendingEpoch != null) {
      _pendingEpoch = null;
      onChanged?.call();
    }
  }

  void dispose() {
    _disposed = true;
    _operationGeneration++;
    _debounceTimer?.cancel();
  }
}
