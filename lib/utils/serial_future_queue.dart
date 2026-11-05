/// Runs asynchronous operations one at a time without allowing a failed
/// operation to poison the queue tail.
class SerialFutureQueue {
  Future<void>? _tail;

  Future<T> run<T>(Future<T> Function() operation) {
    final previous = _tail;
    // An idle queue must use the caller's async zone. Keeping a completed
    // tail would retain an old clock, which can stall later widget tests.
    final operationFuture = previous == null ? Future<T>.microtask(operation) : previous.then((_) => operation());
    late final Future<void> tail;
    final result = operationFuture.whenComplete(() {
      // Reset, or another queued operation, may have replaced this tail.
      if (identical(_tail, tail)) _tail = null;
    });
    tail = _settle(result);
    _tail = tail;
    return result;
  }

  Future<void> get settled => _tail ?? Future<void>.value();

  void reset() {
    _tail = null;
  }

  static Future<void> _settle<T>(Future<T> operation) async {
    try {
      await operation;
    } catch (_) {
      // The returned operation future carries the error to its caller. The
      // internal tail only represents when the queue may start its next item.
    }
  }
}
