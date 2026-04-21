import 'dart:async';

/// Base class for singleton notifiers with broadcast stream support.
///
/// Provides reusable stream controller management. Subclasses define the
/// event type [T]. Once [dispose] is called, further use will throw —
/// subclasses are intended to be singletons living for the app lifetime.
abstract class BaseNotifier<T> {
  StreamController<T>? _controller;
  bool _disposed = false;

  StreamController<T> get _ensureController {
    if (_disposed) {
      throw StateError('BaseNotifier<$T> used after dispose()');
    }
    return _controller ??= StreamController<T>.broadcast();
  }

  /// Stream of all events.
  Stream<T> get stream => _ensureController.stream;

  /// Emit an event to all listeners.
  void notify(T event) => _ensureController.add(event);

  /// Permanently close the controller. Further access throws.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _controller?.close();
    _controller = null;
  }
}
