import 'dart:async';

/// Coalesces full and targeted delta loads behind one in-flight drain.
///
/// A full load takes priority and supersedes every queued delta. Requests made
/// while a pass is running share the drain future and are replayed as trailing
/// work. The callbacks own fetch, commit, and failure policy.
final class CoalescedLoadCoordinator<T> {
  factory CoalescedLoadCoordinator({
    required Future<void> Function() onFull,
    required Future<void> Function(Set<T>) onDelta,
  }) => CoalescedLoadCoordinator._(onFull, onDelta);

  CoalescedLoadCoordinator._(this._onFull, this._onDelta);

  final Future<void> Function() _onFull;
  final Future<void> Function(Set<T>) _onDelta;

  final Set<T> _pendingDelta = {};
  Future<void>? _inFlight;
  bool _pendingFull = false;
  bool _disposed = false;

  Future<void> requestFull() {
    if (_disposed) return Future<void>.value();
    _pendingFull = true;
    return _ensureDrain();
  }

  Future<void> requestDelta(Iterable<T> values) {
    if (_disposed) return Future<void>.value();
    _pendingDelta.addAll(values);
    if (_pendingDelta.isEmpty) return _inFlight ?? Future<void>.value();
    return _ensureDrain();
  }

  /// Discards trailing work without interrupting the active callback.
  void clearPending() {
    if (_disposed) return;
    _pendingFull = false;
    _pendingDelta.clear();
  }

  /// Prevents new work and discards work queued behind the active callback.
  void dispose() {
    _disposed = true;
    _pendingFull = false;
    _pendingDelta.clear();
  }

  Future<void> _ensureDrain() {
    final active = _inFlight;
    if (active != null) return active;

    // Install the shared future before invoking a callback so a synchronous,
    // reentrant request is queued behind this drain rather than starting one.
    final completer = Completer<void>();
    final future = completer.future;
    _inFlight = future;
    _drain().then(
      (_) {
        if (!_disposed && identical(_inFlight, future)) _inFlight = null;
        completer.complete();
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!_disposed && identical(_inFlight, future)) _inFlight = null;
        completer.completeError(error, stackTrace);
      },
    );
    return future;
  }

  Future<void> _drain() async {
    while ((_pendingFull || _pendingDelta.isNotEmpty) && !_disposed) {
      if (_pendingFull) {
        _pendingFull = false;
        _pendingDelta.clear();
        await _onFull();
      } else {
        final values = Set<T>.of(_pendingDelta);
        _pendingDelta.clear();
        await _onDelta(values);
      }
    }
  }
}
