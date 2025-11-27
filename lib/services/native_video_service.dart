import 'dart:io';
import 'package:flutter/services.dart';

/// Service to control the native MPV video layer on macOS.
///
/// This service provides a platform channel interface to control
/// the native MPV-based Metal rendering layer behind the Flutter view.
class NativeVideoService {
  static const _channel = MethodChannel('com.plezy/mpv_player');
  static const _eventChannel = EventChannel('com.plezy/mpv_player/events');

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

  /// Initialize the native MPV player and Metal layer.
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
      print('[NativeVideoService] initialize result: $_isInitialized');
      return _isInitialized;
    } on PlatformException catch (e) {
      print('[NativeVideoService] Failed to initialize: ${e.message}');
      return false;
    }
  }

  /// Show or hide the Metal rendering layer.
  Future<bool> setVisible(bool visible) async {
    if (!isSupported || !_isInitialized) {
      return false;
    }

    try {
      await _channel.invokeMethod('setVisible', {'visible': visible});
      _isVisible = visible;
      print('[NativeVideoService] setVisible($visible)');
      return true;
    } on PlatformException catch (e) {
      print('[NativeVideoService] Failed to set visibility: ${e.message}');
      return false;
    }
  }

  /// Open a media file for playback.
  Future<void> open(String url, {bool play = true}) async {
    if (!isSupported || !_isInitialized) {
      return;
    }

    try {
      await _channel.invokeMethod('open', {'url': url, 'play': play});
      print('[NativeVideoService] open($url, play: $play)');
    } on PlatformException catch (e) {
      print('[NativeVideoService] Failed to open: ${e.message}');
    }
  }

  /// Start playback.
  Future<void> play() async {
    if (!isSupported || !_isInitialized) return;
    try {
      await _channel.invokeMethod('play');
    } on PlatformException catch (e) {
      print('[NativeVideoService] Failed to play: ${e.message}');
    }
  }

  /// Pause playback.
  Future<void> pause() async {
    if (!isSupported || !_isInitialized) return;
    try {
      await _channel.invokeMethod('pause');
    } on PlatformException catch (e) {
      print('[NativeVideoService] Failed to pause: ${e.message}');
    }
  }

  /// Stop playback.
  Future<void> stop() async {
    if (!isSupported || !_isInitialized) return;
    try {
      await _channel.invokeMethod('stop');
    } on PlatformException catch (e) {
      print('[NativeVideoService] Failed to stop: ${e.message}');
    }
  }

  /// Seek to a position in seconds.
  Future<void> seek(double position) async {
    if (!isSupported || !_isInitialized) return;
    try {
      await _channel.invokeMethod('seek', {'position': position});
    } on PlatformException catch (e) {
      print('[NativeVideoService] Failed to seek: ${e.message}');
    }
  }

  /// Set volume (0.0 to 100.0).
  Future<void> setVolume(double volume) async {
    if (!isSupported || !_isInitialized) return;
    try {
      await _channel.invokeMethod('setVolume', {'volume': volume});
    } on PlatformException catch (e) {
      print('[NativeVideoService] Failed to set volume: ${e.message}');
    }
  }

  /// Set playback rate.
  Future<void> setRate(double rate) async {
    if (!isSupported || !_isInitialized) return;
    try {
      await _channel.invokeMethod('setRate', {'rate': rate});
    } on PlatformException catch (e) {
      print('[NativeVideoService] Failed to set rate: ${e.message}');
    }
  }

  /// Select an audio track by ID.
  Future<void> selectAudioTrack(String id) async {
    if (!isSupported || !_isInitialized) return;
    try {
      await _channel.invokeMethod('selectAudioTrack', {'id': id});
    } on PlatformException catch (e) {
      print('[NativeVideoService] Failed to select audio track: ${e.message}');
    }
  }

  /// Select a subtitle track by ID.
  Future<void> selectSubtitleTrack(String id) async {
    if (!isSupported || !_isInitialized) return;
    try {
      await _channel.invokeMethod('selectSubtitleTrack', {'id': id});
    } on PlatformException catch (e) {
      print('[NativeVideoService] Failed to select subtitle track: ${e.message}');
    }
  }

  /// Dispose of the native resources.
  Future<void> dispose() async {
    if (!isSupported) {
      return;
    }

    try {
      await _channel.invokeMethod('dispose');
      _isInitialized = false;
      _isVisible = false;
      print('[NativeVideoService] disposed');
    } on PlatformException catch (e) {
      print('[NativeVideoService] Failed to dispose: ${e.message}');
    }
  }
}
