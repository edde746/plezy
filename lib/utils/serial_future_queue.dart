/// Runs asynchronous operations one at a time without allowing a failed
/// operation to poison the queue tail.
class SerialFutureQueue {
  Future<void> _tail = Future<void>.value();

  Future<T> run<T>(Future<T> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = _settle(result);
    return result;
  }

  Future<void> get settled => _tail;

  void reset() {
    _tail = Future<void>.value();
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
