import 'package:wakelock_plus/wakelock_plus.dart';

import '../../utils/app_logger.dart';

typedef WakelockPlatformToggle = Future<void> Function(bool enabled);

/// Serializes fire-and-forget wakelock requests around the latest desired state.
class WakelockController {
  WakelockController({WakelockPlatformToggle? platformToggle})
    : _platformToggle = platformToggle ?? _togglePlatformWakelock;

  final WakelockPlatformToggle _platformToggle;

  Future<void> _tail = Future<void>.value();
  bool? _effectiveEnabled;
  bool _desiredEnabled = false;

  /// Requests a wakelock state and completes after this queued reconciliation.
  ///
  /// Platform failures are logged and absorbed so detached UI callers cannot
  /// produce unhandled errors. A failed state is not recorded as effective;
  /// the same value can therefore be retried by a later explicit request.
  Future<void> setEnabled(bool enabled) {
    _desiredEnabled = enabled;
    final operation = _tail.then((_) => _reconcile());
    _tail = operation;
    return operation;
  }

  Future<void> _reconcile() async {
    while (_effectiveEnabled != _desiredEnabled) {
      final target = _desiredEnabled;
      try {
        await _platformToggle(target);
        _effectiveEnabled = target;
      } catch (error, stackTrace) {
        appLogger.w('Wakelock ${target ? 'enable' : 'disable'} failed', error: error, stackTrace: stackTrace);

        // Do not spin on a persistent failure. If an opposing request arrived
        // during the await, it still gets one attempt before this operation
        // settles; an identical state retries only through another setEnabled.
        if (_desiredEnabled == target) return;
      }
    }
  }
}

Future<void> _togglePlatformWakelock(bool enabled) => WakelockPlus.toggle(enable: enabled);
