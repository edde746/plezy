import 'dart:async';

/// Base class for singleton notifiers with broadcast stream support.
///
/// Provides reusable stream controller management with lazy initialization
/// and automatic recreation if disposed. Subclasses define the event type [T].
abstract class BaseNotifier<T> {
  StreamController<T>? _controller;

  /// Ensure controller exists (creates if null or closed).
  StreamController<T> get _ensureController {
    if (_controller == null || _controller!.isClosed) {
      _controller = StreamController<T>.broadcast();
    }
    return _controller!;
  }

  /// Stream of all events.
  Stream<T> get stream => _ensureController.stream;

  /// Emit an event to all listeners.
  void notify(T event) => _ensureController.add(event);

  /// Dispose controller (can be reinitialized later by accessing stream).
  void dispose() {
    _controller?.close();
    _controller = null;
  }
}
