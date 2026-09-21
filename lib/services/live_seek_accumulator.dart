import 'dart:async';

/// Inclusive epoch-second window a live seek may target (the capture buffer's
/// seekable range). `start` ≈ earliest seekable point, `end` ≈ the live edge.
typedef LiveSeekBounds = ({int start, int end});

/// Relative live skip entry point: accumulates [deltaSeconds] and returns the
/// seconds actually applied in the direction of the press, or zero — which is
/// all a readout may announce. See [LiveSeekAccumulator.seekBy].
typedef LiveSeekBy = int Function(int deltaSeconds);

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
  ///
  /// Returns the seconds actually applied in the direction of the press: the
  /// distance from the current base to the target the window let through.
  /// Zero when there is no seekable window, when the target is already pinned
  /// at an edge — the common fast-forward-at-live-edge press — or when a window
  /// that moved under a pending burst drags the target against the press, so a
  /// readout announcing this never promises travel that is not going to happen
  /// and never counts a rewind that actually went forward (#2425).
  ///
  /// The base is the raw epoch and it caps the target, not the window's `end`:
  /// unlike a VOD duration, the window is only as fresh as the 10s heartbeat,
  /// so at the live edge the playhead routinely runs a few seconds past `end`
  /// while genuinely sitting inside the buffer. A rewind from there really does
  /// travel the full step, and one shorter than the overshoot must not clamp
  /// back onto the origin and vanish; the flush re-clamps against whatever
  /// window is current by then. Compare `DebouncedSeekAccumulator.seekBy`,
  /// which measures from the clamped origin for the opposite reason.
  int seekBy(int deltaSeconds) {
    if (_disposed) return 0;
    final window = bounds();
    if (window == null) return 0;

    final base = _pendingEpoch ?? currentEpoch();
    final ceiling = base > window.end ? base : window.end;
    final target = (base + deltaSeconds).clamp(window.start, ceiling);
    final travelled = target - base;
    final applied = travelled.sign == deltaSeconds.sign ? travelled : 0;
    // Do not rebuild the stream when a fresh press applies nothing (most
    // commonly fast-forward at live edge). Once a burst has a pending target,
    // keep its normal debounce semantics: the pin follows the clamp so it lands
    // where the flush would anyway.
    if (_pendingEpoch == null && applied == 0) return 0;
    if (target != _pendingEpoch) {
      _pendingEpoch = target;
      onChanged?.call();
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () => unawaited(_flush()));
    return applied;
  }

  Future<void> _flush() async {
    if (_flushing || _disposed) return;
    final target = _pendingEpoch;
    if (target == null) return;
    // We're committing to this seek; don't let a stale debounce double-fire it.
    _debounceTimer?.cancel();

    _flushing = true;
    final operationGeneration = _operationGeneration;
    try {
      await seek(target);
    } catch (_) {
      // The source owns any remaining clock uncertainty. A failed re-open
      // must still hand off to newer input or release this burst's target.
    } finally {
      if (operationGeneration == _operationGeneration) {
        _flushing = false;
      }
    }
    if (_disposed || operationGeneration != _operationGeneration) return;

    // A press landed during the network round-trip + calibration. Its
    // debounce may already have fired while we were flushing, so dispatch
    // it after every terminal outcome, not only a successful calibration.
    if (_pendingEpoch != target) {
      unawaited(_flush());
      return;
    }

    // Success calibrated the source; failure leaves uncertainty with the
    // source clock. Neither outcome should keep this completed burst pinned.
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
