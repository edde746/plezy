import 'dart:async';

/// Acceleration tier shared by video and music timeline key-repeat seeking.
double steppedSeekMultiplier(int repeatCount) {
  if (repeatCount <= 5) return 1.5;
  if (repeatCount <= 15) return 3.0;
  if (repeatCount <= 30) return 6.0;
  return 10.0;
}

/// Coalesces a burst of relative timeline steps into one absolute seek.
///
/// The pending target remains pinned until playback reaches it (or the settle
/// ceiling expires), so a slow seek cannot make the next burst rebase from a
/// stale player position.
///
/// The pin is dropped as soon as something else lays claim to the playhead —
/// feed [playheadJumps] every discontinuity the player announces, and any
/// target that is not this accumulator's own commit retires it, so the next
/// step rebases from where the user actually is rather than from a superseded
/// skip (#1819). Those announcements are request-time intent, so the pin is
/// retired as soon as another source asks, not once the backend has obeyed.
class DebouncedSeekAccumulator {
  DebouncedSeekAccumulator({
    required this.currentPosition,
    required this.duration,
    required this.seek,
    this.onChanged,
    this.onBurstAbandoned,
    Stream<Duration?>? playheadJumps,
    this.debounce = const Duration(milliseconds: 800),
    this.settlePoll = const Duration(seconds: 2),
    this.settleTolerance = const Duration(seconds: 3),
    this.settleCeiling = const Duration(seconds: 10),
  }) {
    _jumpSubscription = playheadJumps?.listen(observePlayheadJump);
  }

  /// How far a reported jump may land from the pinned target and still count as
  /// this accumulator's own commit coming back around. Wide enough to absorb
  /// re-clamping on the way to the backend, narrow enough that a real jump
  /// elsewhere always retires the pin — and a foreign jump landing inside it is
  /// indistinguishable from the pinned target anyway.
  static const Duration ownJumpTolerance = Duration(milliseconds: 250);

  final Duration Function() currentPosition;
  final Duration Function() duration;
  final void Function(Duration target) seek;

  /// Fires whenever the pending target changes, including when it is retired.
  /// This is a repaint ping for previews, not a seek notification.
  final void Function()? onChanged;

  /// Fires whenever a pending target is dropped instead of being played out —
  /// a foreign playhead jump, a player swap, or the owner cancelling outright.
  /// Callers use this to drop state that described that burst, such as a
  /// running skip total.
  ///
  /// The target may already have been committed: a burst stays pinned after its
  /// seek is dispatched, and something else superseding it then still leaves
  /// that description stale. Only the natural settle, where playback reaches
  /// the target, retires a pin without firing this.
  final void Function()? onBurstAbandoned;

  final Duration debounce;
  final Duration settlePoll;
  final Duration settleTolerance;
  final Duration settleCeiling;

  Duration? _pendingPosition;
  Duration? _lastFlushedPosition;
  Duration? _ownSeekTarget;
  Timer? _debounceTimer;
  Timer? _settleTimer;
  StreamSubscription<Duration?>? _jumpSubscription;
  bool _disposed = false;

  Duration? get pendingPosition => _pendingPosition;

  /// Retire the pinned target when the playhead lands somewhere this
  /// accumulator did not put it. A null [target] is a jump whose destination
  /// the backend kept to itself, which is always foreign by definition.
  ///
  /// Position alone cannot decide this: a seek writes its target optimistically
  /// and stale backend ticks then report the pre-seek position again, so an
  /// unapplied slow seek looks exactly like a jump elsewhere.
  void observePlayheadJump(Duration? target) {
    if (_disposed) return;
    final own = _ownSeekTarget;
    if (target != null && own != null && (target - own).abs() <= ownJumpTolerance) {
      // The commit this accumulator just issued, echoed back. Matching on the
      // target rather than on arrival order keeps the pin alive even if a
      // backend reports it late.
      _ownSeekTarget = null;
      return;
    }
    if (_pendingPosition == null) return;
    cancel();
  }

  /// Re-point at another player's jump stream after the owner swapped players.
  ///
  /// The pending target described the old player's timeline and its echo will
  /// never arrive now, so it is retired rather than carried across.
  void attachPlayheadJumps(Stream<Duration?>? playheadJumps) {
    if (_disposed) return;
    unawaited(_jumpSubscription?.cancel());
    _jumpSubscription = playheadJumps?.listen(observePlayheadJump);
    cancel();
  }

  void seekBy(Duration delta) {
    if (_disposed) return;
    final maximum = duration();
    if (maximum <= Duration.zero) return;

    final base = _pendingPosition ?? currentPosition();
    final targetMs = (base + delta).inMilliseconds.clamp(0, maximum.inMilliseconds);
    final target = Duration(milliseconds: targetMs);
    if (target != _pendingPosition) {
      _settleTimer?.cancel();
      _settleTimer = null;
      _pendingPosition = target;
      _lastFlushedPosition = null;
      onChanged?.call();
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, flush);
  }

  void flush() {
    if (_disposed) return;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    final target = _pendingPosition;
    if (target == null || target == _lastFlushedPosition) return;
    _lastFlushedPosition = target;
    _ownSeekTarget = target;
    seek(target);
    _scheduleClear(target);
  }

  void _scheduleClear(Duration target) {
    _settleTimer?.cancel();
    var elapsed = Duration.zero;
    void poll() {
      if (_disposed || _pendingPosition != target) return;
      elapsed += settlePoll;
      if ((currentPosition() - target).abs() <= settleTolerance || elapsed >= settleCeiling) {
        _pendingPosition = null;
        _lastFlushedPosition = null;
        _settleTimer = null;
        onChanged?.call();
        return;
      }
      _settleTimer = Timer(settlePoll, poll);
    }

    _settleTimer = Timer(settlePoll, poll);
  }

  /// Drop the pending burst without committing it.
  void cancel() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _settleTimer?.cancel();
    _settleTimer = null;
    _lastFlushedPosition = null;
    _ownSeekTarget = null;
    if (_pendingPosition != null) {
      _pendingPosition = null;
      onChanged?.call();
      onBurstAbandoned?.call();
    }
  }

  void dispose() {
    _disposed = true;
    unawaited(_jumpSubscription?.cancel());
    _jumpSubscription = null;
    _debounceTimer?.cancel();
    _settleTimer?.cancel();
  }
}
