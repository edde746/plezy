/// Memoizes a `static Future<T> getInstance()` singleton whose construction is
/// cheap but whose initialization is async.
///
/// The instance is published *before* initialization runs, so sync accessors
/// (`isTVSync`, `isReduced`, ...) see it immediately. Concurrent callers await
/// the one in-flight initialization, and a failed initialization rolls the
/// instance back so the next call retries — the `identical` guards keep that
/// rollback safe once a later call has replaced the memoized state.
///
/// The `debug*` members are test hooks; owners re-expose them behind their own
/// `@visibleForTesting` forwarders.
class AsyncSingleton<T extends Object> {
  T? _instance;
  Future<void>? _initialization;

  /// Awaited before each initialization run, to hold initialization open while
  /// a test exercises concurrent callers.
  Future<void>? debugGate;

  /// The memoized instance, which may still be initializing. Null before the
  /// first [getInstance] call and after a failed initialization.
  T? get instance => _instance;

  /// Returns the memoized instance, building it with [create] and running
  /// [initialize] on it the first time.
  Future<T> getInstance(T Function() create, Future<void> Function(T instance) initialize) async {
    final existing = _instance;
    if (existing != null) {
      final inFlight = _initialization;
      if (inFlight != null) await inFlight;
      return existing;
    }

    final instance = create();
    _instance = instance;
    final initialization = _initialize(instance, initialize);
    _initialization = initialization;
    try {
      await initialization;
    } catch (_) {
      if (identical(_instance, instance)) _instance = null;
      rethrow;
    } finally {
      if (identical(_initialization, initialization)) _initialization = null;
    }
    return instance;
  }

  Future<void> _initialize(T instance, Future<void> Function(T instance) initialize) async {
    final gate = debugGate;
    if (gate != null) await gate;
    await initialize(instance);
  }

  /// Drops the memoized state and the gate, optionally seeding [instance] so
  /// sync accessors can be exercised without initializing.
  void debugReset({T? instance}) {
    _instance = instance;
    _initialization = null;
    debugGate = null;
  }
}
