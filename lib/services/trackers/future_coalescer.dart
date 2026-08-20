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

  /// Detach the in-flight future (it keeps running, but the next [run]
  /// starts fresh instead of joining it). The identical-guard above keeps
  /// the detached future's completion from clearing a newer slot.
  void reset() {
    _inFlight = null;
  }
}

/// Keyed [FutureCoalescer]: one in-flight future per key. Used for the
/// static per-identity re-auth/refresh maps (Trakt refresh-by-token, Seerr
/// re-auth-by-instance) so concurrent 401s trigger one login each.
class KeyedFutureCoalescer<K, T> {
  final Map<K, Future<T>> _inFlight = {};

  Future<T> run(K key, Future<T> Function() create) {
    final existing = _inFlight[key];
    if (existing != null) return existing;

    late final Future<T> future;
    future = create().whenComplete(() {
      if (identical(_inFlight[key], future)) _inFlight.remove(key);
    });
    _inFlight[key] = future;
    return future;
  }

  /// Detach every in-flight future — the keyed form of [FutureCoalescer.reset].
  void clear() {
    _inFlight.clear();
  }
}

/// Keyed cache of loads: like [KeyedFutureCoalescer], but a successful future
/// stays memoized instead of being dropped on completion, and only a failure
/// evicts the key so the next call retries. [onError] fires once per failed
/// load, before the error is rethrown to every caller.
class KeyedFutureCache<K, T> {
  final Map<K, Future<T>> _entries = {};

  Future<T> run(K key, Future<T> Function() create, {void Function(Object error)? onError}) {
    final existing = _entries[key];
    if (existing != null) return existing;

    late final Future<T> future;
    future = create().catchError((Object e) {
      if (identical(_entries[key], future)) _entries.remove(key);
      onError?.call(e);
      throw e;
    });
    _entries[key] = future;
    return future;
  }

  void clear() {
    _entries.clear();
  }
}
