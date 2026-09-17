import 'dart:async';
import '../media/live_tv_timeline.dart';

/// Inclusive epoch-second window a live seek may target (the capture buffer's
/// seekable range). `start` ≈ earliest seekable point, `end` ≈ the live edge.
typedef LiveSeekBounds = LiveTvSeekWindow;

/// Coalesces rapid relative live-TV skips into a single transcode re-open.
///
/// Live time-shift seeks don't use `player.seek()` — each one re-opens a fresh
/// Plex transcode session at an epoch offset. This accumulates a stable
/// in-memory target ([pendingEpoch]) so every press adds onto the previous
/// target rather than re-reading player state while a source replacement is
/// in flight, then debounces the actual re-open so a whole burst collapses
/// into one [seek] (#1253).
///
/// [seek] waits for source readiness. Pending targets describe intent only;
/// the session separately reports playback timing and its accuracy (#2100).
class LiveSeekAccumulator {
  LiveSeekAccumulator({
    required this.seek,
    required this.currentEpoch,
    required this.bounds,
    this.onChanged,
    this.seekLive,
    this.debounce = const Duration(milliseconds: 300),
  });

  /// Re-open and calibrate the live stream at the target epoch.
  ///
  /// Returns false when URL resolution, open, or clock calibration fails.
  final Future<bool> Function(double targetEpoch) seek;
  final Future<bool> Function()? seekLive;

  /// The calibrated live playback position as an absolute epoch second, used
  /// as the base for a fresh burst.
  final double? Function() currentEpoch;

  /// Current seekable window, or null when there is no live capture buffer.
  final LiveSeekBounds? Function() bounds;

  /// Notified whenever [pendingEpoch] changes (so the owner can rebuild UI and
  /// recompute live-edge state).
  final void Function()? onChanged;

  /// How long after the last press to wait before executing the seek.
  final Duration debounce;

  double? _pendingEpoch;
  bool _pendingLive = false;
  bool _previewProgram = false;
  int _intentGeneration = 0;
  int get intentGeneration => _intentGeneration;
  Timer? _debounceTimer;
  bool _flushing = false;
  bool _disposed = false;
  int _operationGeneration = 0;

  /// The accumulated target while a skip is pending or settling, else null.
  /// Presentation must render this separately from observed playback.
  double? get pendingEpoch => _pendingEpoch;

  /// Remote/keyboard destination used only for program presentation. Remains
  /// available through debounce and source readiness, then clears on any outcome.
  double? get programPreviewEpoch => _previewProgram ? _pendingEpoch : null;

  /// Accumulate a relative skip of [deltaSeconds] and (re)arm the debounce.
  /// No-op when there is no seekable window.
  void seekBy(int deltaSeconds, {bool previewProgram = false}) {
    if (_disposed) return;
    final window = bounds();
    if (window == null || !window.isValid) return;

    final base = _pendingEpoch ?? currentEpoch();
    if (base == null) return;
    final clampedBase = window.target(base)!;
    final target = window.target(base + deltaSeconds)!;
    // Do not rebuild the stream when a relative skip is clamped back to the
    // position it already occupies (most commonly fast-forward at live edge).
    // Once a burst has a pending target, keep its normal debounce semantics.
    if (_pendingEpoch == null && target == clampedBase) return;
    if (_pendingEpoch == target && !_pendingLive) {
      if (_previewProgram != previewProgram) {
        _previewProgram = previewProgram;
        onChanged?.call();
      }
      return;
    }
    _intentGeneration++;
    _pendingLive = false;
    _previewProgram = previewProgram;
    _pendingEpoch = target;
    onChanged?.call(); // Also notify when only live/offset operation changes.

    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () => unawaited(_flush()));
  }

  /// Absolute scrubs share pending ownership with skips and return-to-live.
  void seekTo(double targetEpoch) {
    final window = bounds();
    if (_disposed || window == null || !window.isValid || !targetEpoch.isFinite) return;
    _intentGeneration++;
    _pendingEpoch = window.target(targetEpoch);
    _pendingLive = false;
    _previewProgram = false;
    onChanged?.call();
    unawaited(_flush());
  }

  /// Live is a backend operation, allowed even if old seek bounds are stale.
  /// Its preview is explicitly pending; it is never confirmed playback.
  void jumpToLive({double? previewEpoch}) {
    final target = bounds()?.endEpoch ?? previewEpoch;
    if (_disposed || seekLive == null || target == null || !target.isFinite) return;
    _intentGeneration++;
    _pendingEpoch = target;
    _pendingLive = true;
    _previewProgram = false;
    onChanged?.call();
    unawaited(_flush());
  }

  Future<void> _flush() async {
    if (_flushing || _disposed) return;
    final requested = _pendingEpoch;
    final window = bounds();
    if (requested == null) return;
    if (!_pendingLive && (window == null || !window.isValid)) {
      cancel();
      return;
    }
    final target = _pendingLive ? requested : window!.target(requested)!;
    if (_pendingEpoch != target) {
      _pendingEpoch = target;
      onChanged?.call();
    }
    final live = _pendingLive;
    final intentGeneration = _intentGeneration;
    // We're committing to this seek; don't let a stale debounce double-fire it.
    _debounceTimer?.cancel();

    _flushing = true;
    final operationGeneration = _operationGeneration;
    try {
      if (live && seekLive != null) {
        await seekLive!();
      } else {
        await seek(target);
      }
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
    if (_intentGeneration != intentGeneration) {
      unawaited(_flush());
      return;
    }

    // Success calibrated the source; failure leaves uncertainty with the
    // source clock. Neither outcome should keep this completed burst pinned.
    _pendingEpoch = null;
    _previewProgram = false;
    onChanged?.call();
  }

  /// Drop any queued/settling seek. Used when the session is about to be
  /// replaced (channel switch, retry) or superseded by an absolute seek, so a
  /// stale debounced seek can't fire against the new stream.
  void cancel() {
    _intentGeneration++;
    _operationGeneration++;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _flushing = false;
    _previewProgram = false;
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
