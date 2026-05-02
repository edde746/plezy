class FutureCoalescer<T> {
  Future<T>? _inFlight;

  Future<T> run(Future<T> Function() create) {
    final existing = _inFlight;
    if (existing != null) return existing;

    late final Future<T> future;
    future = create().whenComplete(() {
      if (identical(_inFlight, future)) _inFlight = null;
    });
    _inFlight = future;
    return future;
  }
}
