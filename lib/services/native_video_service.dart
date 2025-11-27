import 'dart:io';
import 'package:flutter/services.dart';

/// Service to control the native Metal video layer on macOS.
///
/// This service provides a platform channel interface to show/hide
/// a native Metal rendering layer behind the Flutter view. This is
/// the foundation for native mpv-based
/// video playback on macOS.
class NativeVideoService {
  static const _channel = MethodChannel('com.plezy/native_video');

  /// Singleton instance
  static final NativeVideoService _instance = NativeVideoService._();
  static NativeVideoService get instance => _instance;

  NativeVideoService._();

  /// Factory constructor returns singleton
  factory NativeVideoService() => _instance;

  bool _isInitialized = false;
  bool _isVisible = false;

  /// Check if running on macOS (only platform with native video layer)
  bool get isSupported => Platform.isMacOS;

  /// Check if the service has been initialized
  bool get isInitialized => _isInitialized;

  /// Check if the Metal layer is currently visible
  bool get isVisible => _isVisible;

  /// Initialize the native Metal layer.
  ///
  /// This creates the MTKView and Metal renderer, but keeps
  /// the layer hidden until [setVisible] is called.
  ///
  /// Returns true if initialization was successful.
  Future<bool> initialize() async {
    if (!isSupported) {
      return false;
    }

    if (_isInitialized) {
      return true;
    }

    try {
      final result = await _channel.invokeMethod<bool>('initialize');
      _isInitialized = result ?? false;
      return _isInitialized;
    } on PlatformException catch (e) {
      print('[NativeVideoService] Failed to initialize: ${e.message}');
      return false;
    }
  }

  /// Show or hide the Metal rendering layer.
  ///
  /// When visible, the Metal layer renders behind the transparent
  /// Flutter view, allowing Flutter controls to overlay native content.
  Future<bool> setVisible(bool visible) async {
    if (!isSupported || !_isInitialized) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>(
        'setVisible',
        {'visible': visible},
      );
      _isVisible = visible && (result ?? false);
      return result ?? false;
    } on PlatformException catch (e) {
      print('[NativeVideoService] Failed to set visibility: ${e.message}');
      return false;
    }
  }

  /// Dispose of the native resources.
  ///
  /// Call this when you're done with the native video layer
  /// to free up GPU resources.
  Future<void> dispose() async {
    if (!isSupported) {
      return;
    }

    try {
      await _channel.invokeMethod('dispose');
      _isInitialized = false;
      _isVisible = false;
    } on PlatformException catch (e) {
      print('[NativeVideoService] Failed to dispose: ${e.message}');
    }
  }
}
