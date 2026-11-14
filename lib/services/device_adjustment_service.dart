import 'dart:async' show unawaited;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../utils/app_logger.dart';

/// Mobile-only bridge for screen brightness and OS media volume.
///
/// Values are normalized to 0.0-1.0. Unsupported platforms return null for
/// getters and ignore setters.
class DeviceAdjustmentService {
  DeviceAdjustmentService({MethodChannel? channel}) : _channel = channel ?? const MethodChannel(_channelName);

  static const String _channelName = 'com.plezy/device_adjustment';
  static final DeviceAdjustmentService instance = DeviceAdjustmentService();

  final MethodChannel _channel;
  AppLifecycleListener? _lifecycleListener;
  VoidCallback? onResume;
  bool _restoreSuppressed = false;
  bool _brightnessChanged = false;
  int _brightnessGeneration = 0;
  Future<void> _brightnessQueue = Future<void>.value();

  /// Called with the new system volume (0.0–1.0) when it changes, including
  /// from the hardware buttons. Null to stop listening.
  void Function(double volume)? onSystemVolumeChanged;

  /// Start reporting system volume changes to [onSystemVolumeChanged].
  Future<void> startVolumeButtonWatch() async {
    _ensureVolumeHandler();
    try {
      await _channel.invokeMethod<void>('startVolumeButtonWatch');
    } on MissingPluginException {
      // Unsupported platform: the buttons keep their normal meaning.
    } on PlatformException catch (error) {
      appLogger.d('Could not watch the volume buttons: ${error.code}');
    }
  }

  Future<void> stopVolumeButtonWatch() async {
    try {
      await _channel.invokeMethod<void>('stopVolumeButtonWatch');
    } on MissingPluginException {
      // Nothing was watching.
    } on PlatformException catch (error) {
      appLogger.d('Could not stop watching the volume buttons: ${error.code}');
    }
  }

  /// Plays silence on this device so iOS treats the app as the one playing.
  ///
  /// iOS only sends lock-screen, Control Center and headphone commands (an
  /// AirPods press) to the app that is playing audio, and only keeps a
  /// backgrounded app running while it plays. Music going to a speaker in
  /// another room plays nothing here, so without this those controls reach
  /// another app, and the volume buttons stop working once the phone locks.
  Future<void> startNowPlayingKeepAlive() async {
    try {
      await _channel.invokeMethod<void>('startNowPlayingKeepAlive');
    } on MissingPluginException {
      // Not iOS: nothing to hold.
    } on PlatformException catch (error) {
      appLogger.d('Could not hold the audio session: ${error.code}');
    }
  }

  Future<void> stopNowPlayingKeepAlive() async {
    try {
      await _channel.invokeMethod<void>('stopNowPlayingKeepAlive');
    } on MissingPluginException {
      // Nothing was held.
    } on PlatformException catch (error) {
      appLogger.d('Could not release the audio session: ${error.code}');
    }
  }

  bool _volumeHandlerInstalled = false;

  void _ensureVolumeHandler() {
    if (_volumeHandlerInstalled) return;
    _volumeHandlerInstalled = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'onSystemVolumeChanged') return null;
      final value = call.arguments;
      if (value is num) onSystemVolumeChanged?.call(value.toDouble());
      return null;
    });
  }

  Future<double?> getBrightness() => _invokeDouble('getBrightness');

  Future<void> setBrightness(double value) async {
    _ensureLifecycleListener();
    if (!value.isFinite) return;
    final clamped = value.clamp(0.0, 1.0).toDouble();
    final generation = ++_brightnessGeneration;
    _brightnessChanged = true;

    return _enqueueBrightnessOperation(() async {
      if (generation != _brightnessGeneration) return;
      try {
        await _channel.invokeMethod<void>('setBrightness', clamped);
      } on MissingPluginException {
        // Unsupported platform: keep gestures harmless.
        if (generation == _brightnessGeneration) _brightnessChanged = false;
      } on PlatformException catch (error, stackTrace) {
        if (generation == _brightnessGeneration) _brightnessChanged = false;
        appLogger.w('Failed to set screen brightness', error: error, stackTrace: stackTrace);
      }
    });
  }

  Future<void> restoreBrightness() async {
    if (!_brightnessChanged) return;
    final generation = ++_brightnessGeneration;

    return _enqueueBrightnessOperation(() async {
      if (generation != _brightnessGeneration || !_brightnessChanged) return;
      try {
        await _channel.invokeMethod<void>('restoreBrightness');
        if (generation == _brightnessGeneration) _brightnessChanged = false;
      } on MissingPluginException {
        if (generation == _brightnessGeneration) _brightnessChanged = false;
      } on PlatformException catch (error, stackTrace) {
        appLogger.w('Failed to restore screen brightness', error: error, stackTrace: stackTrace);
      }
    });
  }

  Future<void> _enqueueBrightnessOperation(Future<void> Function() operation) {
    final next = _brightnessQueue.catchError((_) {}).then((_) => operation());
    _brightnessQueue = next.catchError((_) {});
    return next;
  }

  Future<double?> getMediaVolume() => _invokeDouble('getMediaVolume');

  /// Whether the volume was set. iOS can refuse — its system slider only
  /// exists once the app has a window — and a caller that measures from the
  /// value it asked for needs to know.
  Future<bool> setMediaVolume(double value) async {
    final clamped = value.clamp(0.0, 1.0);
    try {
      await _channel.invokeMethod<void>('setMediaVolume', clamped);
      return true;
    } on MissingPluginException {
      // Unsupported platform: keep gestures harmless.
      return false;
    } on PlatformException catch (error, stackTrace) {
      appLogger.w('Failed to set media volume', error: error, stackTrace: stackTrace);
      return false;
    }
  }

  Future<double?> _invokeDouble(String method) async {
    try {
      final value = await _channel.invokeMethod<num?>(method);
      final normalized = value?.toDouble();
      return normalized?.clamp(0.0, 1.0).toDouble();
    } on MissingPluginException {
      return null;
    } on PlatformException catch (error, stackTrace) {
      appLogger.w('Failed to call $method', error: error, stackTrace: stackTrace);
      return null;
    }
  }

  void _ensureLifecycleListener() {
    _lifecycleListener ??= AppLifecycleListener(
      onHide: _restoreBrightnessFromLifecycle,
      onPause: _restoreBrightnessFromLifecycle,
      onResume: _handleResume,
      onShow: _handleResume,
      onDetach: _restoreBrightnessFromLifecycle,
    );
  }

  void setRestoreSuppressed(bool suppressed) {
    _restoreSuppressed = suppressed;
  }

  void _restoreBrightnessFromLifecycle() {
    if (_restoreSuppressed) return;
    unawaited(restoreBrightness());
  }

  void _handleResume() {
    onResume?.call();
  }

  /// Reset queue and restore state between tests. A queue future chained in
  /// one `testWidgets` fake-async zone never completes inside the next test's
  /// zone, which would stall every later brightness operation on the shared
  /// [instance].
  @visibleForTesting
  void resetForTesting() {
    dispose();
    _brightnessChanged = false;
    _brightnessGeneration = 0;
    _brightnessQueue = Future<void>.value();
  }

  void dispose() {
    _lifecycleListener?.dispose();
    _lifecycleListener = null;
    onResume = null;
    _restoreSuppressed = false;
  }
}
