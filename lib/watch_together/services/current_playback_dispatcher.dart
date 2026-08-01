import '../../utils/app_logger.dart';

/// Serializes guest media-switch dispatches and provides heartbeat-driven
/// retry: a key is only marked handled after its callback reports success,
/// so a failed switch is re-dispatched by the host's next state heartbeat.
class CurrentPlaybackDispatcher {
  static const dispatchTimeout = Duration(seconds: 30);

  String? _lastHandledKey;
  String? _inFlightKey;
  int _generation = 0;

  String? get inFlightKey => _inFlightKey;

  /// Whether [key] should be dispatched now. A single in-flight slot
  /// serializes dispatches (concurrent navigations would stack player
  /// routes); once it frees, the next heartbeat carries the latest key.
  bool shouldDispatch(String? key) => key != null && key != _lastHandledKey && _inFlightKey == null;

  /// Suppress future dispatches of [key] (e.g. a user-initiated join already
  /// navigating to it).
  void markHandled(String key) => _lastHandledKey = key;

  /// Session left / host exited player: clears state and invalidates any
  /// in-flight completion so a stale success can't suppress a later re-join
  /// of the same media.
  void reset() {
    _generation++;
    _inFlightKey = null;
    _lastHandledKey = null;
  }

  Future<void> dispatch(String key, Future<bool> Function() invoke, {Duration timeout = dispatchTimeout}) async {
    // Synchronous — claims the slot before the first await so a
    // same-microtask second state can't double-dispatch.
    _inFlightKey = key;
    final generation = _generation;
    var handled = false;
    try {
      // then<bool> re-types the future: a throwing async callback is
      // reified as Future<Never>, whose timeout() rejects a bool onTimeout.
      handled = await invoke().then<bool>((value) => value).timeout(timeout, onTimeout: () => false);
    } catch (e, stackTrace) {
      appLogger.w('WatchTogether: media switch dispatch failed for $key', error: e, stackTrace: stackTrace);
    }
    if (generation != _generation) return; // reset() happened mid-flight
    _inFlightKey = null;
    if (handled) _lastHandledKey = key; // else: next heartbeat retries
  }
}
