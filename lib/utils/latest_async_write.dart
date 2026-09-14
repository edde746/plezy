/// Serializes accepted asynchronous writes per key and suppresses work that a
/// newer intent superseded before it began.
///
/// A write already in progress is allowed to finish, then the newest queued
/// write runs after it. This preserves last-intent-wins ordering even when the
/// widget that originated an intent has already been disposed.
final class LatestAsyncWrite<K> {
  final Map<K, _LatestAsyncWriteState> _states = {};

  int begin(K key) {
    final state = _states.putIfAbsent(key, _LatestAsyncWriteState.new);
    return ++state.generation;
  }

  Future<bool> commitIfLatest(K key, int generation, Future<void> Function() write) {
    final state = _states.putIfAbsent(key, _LatestAsyncWriteState.new);
    final operation = state.tail.then((_) async {
      if (state.generation != generation) return false;
      await write();
      return state.generation == generation;
    });
    final settledTail = operation.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    state.tail = settledTail;
    // Do not expose completion until the serial tail has absorbed this
    // operation's error. A caller may immediately enqueue a retry from a
    // different async zone after observing the failure.
    return settledTail.then<bool>((_) {
      if (identical(_states[key], state) && state.generation == generation) {
        _states.remove(key);
      }
      return operation;
    });
  }
}

final class _LatestAsyncWriteState {
  int generation = 0;
  Future<void> tail = Future<void>.value();
}
