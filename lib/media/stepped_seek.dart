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
class DebouncedSeekAccumulator {
  DebouncedSeekAccumulator({
    required this.currentPosition,
    required this.duration,
    required this.seek,
    this.onChanged,
    this.debounce = const Duration(milliseconds: 800),
    this.settlePoll = const Duration(seconds: 2),
    this.settleTolerance = const Duration(seconds: 3),
    this.settleCeiling = const Duration(seconds: 10),
  });

  final Duration Function() currentPosition;
  final Duration Function() duration;
  final void Function(Duration target) seek;
  final void Function()? onChanged;
  final Duration debounce;
  final Duration settlePoll;
  final Duration settleTolerance;
  final Duration settleCeiling;

  Duration? _pendingPosition;
  Duration? _lastFlushedPosition;
  Timer? _debounceTimer;
  Timer? _settleTimer;
  bool _disposed = false;

  Duration? get pendingPosition => _pendingPosition;

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

  void cancel() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _settleTimer?.cancel();
    _settleTimer = null;
    _lastFlushedPosition = null;
    if (_pendingPosition != null) {
      _pendingPosition = null;
      onChanged?.call();
    }
  }

  void dispose() {
    _disposed = true;
    _debounceTimer?.cancel();
    _settleTimer?.cancel();
  }
}
