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

  Future<void> setMediaVolume(double value) async {
    final clamped = value.clamp(0.0, 1.0);
    try {
      await _channel.invokeMethod<void>('setMediaVolume', clamped);
    } on MissingPluginException {
      // Unsupported platform: keep gestures harmless.
    } on PlatformException catch (error, stackTrace) {
      appLogger.w('Failed to set media volume', error: error, stackTrace: stackTrace);
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

  void dispose() {
    _lifecycleListener?.dispose();
    _lifecycleListener = null;
    onResume = null;
    _restoreSuppressed = false;
  }
}
