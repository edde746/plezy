import '../utils/app_logger.dart';

class AppExitPlaybackCleanupService {
  AppExitPlaybackCleanupService._();

  static final AppExitPlaybackCleanupService instance = AppExitPlaybackCleanupService._();

  final Map<Object, Future<void> Function()> _callbacks = <Object, Future<void> Function()>{};
  Future<void>? _pendingExitPreparation;

  void register(Object owner, Future<void> Function() callback) {
    _callbacks[owner] = callback;
  }

  void unregister(Object owner) {
    _callbacks.remove(owner);
  }

  Future<void> prepareForExit() async {
    final pending = _pendingExitPreparation;
    if (pending != null) return pending;

    final future = _runPrepareForExit();
    _pendingExitPreparation = future;
    return future;
  }

  Future<void> _runPrepareForExit() async {
    final callbacks = _callbacks.values.toList(growable: false);
    for (final callback in callbacks) {
      try {
        await callback();
      } catch (e, stackTrace) {
        appLogger.w('Playback exit cleanup failed', error: e, stackTrace: stackTrace);
      }
    }
  }
}
