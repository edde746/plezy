import 'dart:io' show Platform;

import 'package:flutter/services.dart';

import '../font_loader.dart';
import '../models.dart';
import 'player_base.dart';

/// Shared native implementation of [Player] for iOS, macOS, and Android (MPV fallback).
/// Uses MPVKit via platform channels with Metal rendering (Apple) or native window (Android).
class PlayerNative extends PlayerBase {
  static const _methodChannel = MethodChannel('com.plezy/mpv_player');
  static const _eventChannel = EventChannel('com.plezy/mpv_player/events');

  @override
  MethodChannel get methodChannel => _methodChannel;

  @override
  EventChannel get eventChannel => _eventChannel;

  @override
  String get logPrefix => 'MPV';

  @override
  String get playerType => 'mpv';

  // ============================================
  // Initialization
  // ============================================

  Future<void> _ensureInitialized() async {
    if (initialized) return;

    try {
      final result = await methodChannel.invokeMethod<bool>('initialize');
      initialized = result == true;
      if (!initialized) {
        throw Exception('Failed to initialize player');
      }

      // Configure subtitle fonts for libass support
      await _configureSubtitleFonts();

      // Subscribe to MPV properties
      await _observeProperty('time-pos', 'double');
      await _observeProperty('duration', 'double');
      await _observeProperty('pause', 'flag');
      await _observeProperty('paused-for-cache', 'flag');
      await _observeProperty('track-list', (Platform.isAndroid || Platform.isWindows) ? 'string' : 'node');
      await _observeProperty('eof-reached', 'flag');
      await _observeProperty('volume', 'double');
      await _observeProperty('speed', 'double');
      await _observeProperty('aid', 'string');
      await _observeProperty('sid', 'string');
    } catch (e) {
      errorController.add('Initialization failed: $e');
      rethrow;
    }
  }

  Future<void> _observeProperty(String name, String format) async {
    await methodChannel.invokeMethod('observeProperty', {'name': name, 'format': format});
  }

  /// Configures subtitle fonts for libass support.
  /// Provides a comprehensive Unicode font (Go Noto) with CJK coverage to ensure
  /// proper rendering of non-Latin characters in subtitles.
  Future<void> _configureSubtitleFonts() async {
    try {
      final fontDir = await SubtitleFontLoader.loadSubtitleFont();
      if (fontDir != null) {
        // Configure MPV to use the extracted font for libass
        await setProperty('config', 'yes');
        await setProperty('sub-fonts-dir', fontDir);
        await setProperty('sub-font', SubtitleFontLoader.fontName);
      }
    } catch (e) {
      // Font configuration is not critical - continue without it
      errorController.add('Failed to configure subtitle fonts: $e');
    }
  }

  // ============================================
  // Playback Control
  // ============================================

  /// Opens a content:// URI via the platform channel and returns the raw FD number.
  /// Returns null if the call fails.
  Future<int?> _openContentFd(String contentUri) async {
    try {
      final fd = await methodChannel.invokeMethod<int>('openContentFd', {'uri': contentUri});
      return fd;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> open(Media media, {bool play = true, bool isLive = false}) async {
    checkDisposed();
    await _ensureInitialized();

    // Show the video layer
    await setVisible(true);

    // Set HTTP headers for Plex authentication and profile
    if (media.headers != null && media.headers!.isNotEmpty) {
      final headerList = media.headers!.entries.map((e) => '${e.key}: ${e.value}').toList();
      await setProperty('http-header-fields', headerList.join(','));
    }

    // Set start position if provided (must be set before loading file)
    if (media.start != null && media.start!.inSeconds > 0) {
      await setProperty('start', media.start!.inSeconds.toString());
    } else {
      // Reset start position if not resuming
      await setProperty('start', 'none');
    }

    // Set pause BEFORE loadfile to prevent decoder from starting immediately.
    // This is important for adding external subtitles before playback begins,
    // avoiding a race condition that can freeze the video decoder on Android (issue #226).
    if (!play) {
      await setProperty('pause', 'yes');
    }

    // Convert content:// URIs to fdclose:// for MPV on Android (SAF SD card downloads)
    var uri = media.uri;
    if (Platform.isAndroid && uri.startsWith('content://')) {
      final fd = await _openContentFd(uri);
      if (fd != null) {
        uri = 'fdclose://$fd';
      }
    }

    await command(['loadfile', uri, 'replace']);
  }

  @override
  Future<void> play() async {
    checkDisposed();
    await setProperty('pause', 'no');
  }

  @override
  Future<void> pause() async {
    checkDisposed();
    await setProperty('pause', 'yes');
  }

  @override
  Future<void> stop() async {
    checkDisposed();
    await command(['stop']);
    await methodChannel.invokeMethod('setVisible', {'visible': false});
  }

  @override
  Future<void> seek(Duration position) async {
    checkDisposed();
    await command(['seek', (position.inMilliseconds / 1000.0).toString(), 'absolute']);
  }

  // ============================================
  // Track Selection
  // ============================================

  @override
  Future<void> selectAudioTrack(AudioTrack track) async {
    checkDisposed();
    await setProperty('aid', track.id);
  }

  @override
  Future<void> selectSubtitleTrack(SubtitleTrack track) async {
    checkDisposed();
    await setProperty('sid', track.id);
  }

  @override
  Future<void> addSubtitleTrack({required String uri, String? title, String? language, bool select = false}) async {
    checkDisposed();
    final args = ['sub-add', uri, select ? 'select' : 'auto'];
    if (title != null) args.add('title=$title');
    if (language != null) args.add('lang=$language');
    await command(args);
  }

  // ============================================
  // Volume and Rate
  // ============================================

  @override
  Future<void> setVolume(double volume) async {
    checkDisposed();
    await setProperty('volume', volume.toString());
  }

  @override
  Future<void> setRate(double rate) async {
    checkDisposed();
    await setProperty('speed', rate.toString());
  }

  @override
  Future<void> setAudioDevice(AudioDevice device) async {
    checkDisposed();
    await setProperty('audio-device', device.name);
  }

  // ============================================
  // MPV Properties
  // ============================================

  @override
  Future<void> setProperty(String name, String value) async {
    checkDisposed();
    await _ensureInitialized();
    await methodChannel.invokeMethod('setProperty', {'name': name, 'value': value});
  }

  @override
  Future<String?> getProperty(String name) async {
    checkDisposed();
    await _ensureInitialized();
    return await methodChannel.invokeMethod<String>('getProperty', {'name': name});
  }

  @override
  Future<void> command(List<String> args) async {
    checkDisposed();
    await _ensureInitialized();
    await methodChannel.invokeMethod('command', {'args': args});
  }

  // ============================================
  // Passthrough
  // ============================================

  @override
  Future<void> setAudioPassthrough(bool enabled) async {
    checkDisposed();
    if (enabled) {
      await setProperty('audio-spdif', 'ac3,eac3,dts,dts-hd,truehd');
      await setProperty('audio-exclusive', 'yes');
    } else {
      await setProperty('audio-spdif', '');
      await setProperty('audio-exclusive', 'no');
    }
  }

  // ============================================
  // Platform-Specific Overrides
  // ============================================

  @override
  Future<void> updateFrame() async {
    checkDisposed();
    if (!initialized) return;
    // Only iOS and macOS use Metal layer that needs frame updates
    if (Platform.isIOS || Platform.isMacOS) {
      await methodChannel.invokeMethod('updateFrame');
    }
  }

  @override
  Future<void> setVideoFrameRate(double fps, int durationMs) async {
    checkDisposed();
    if (!Platform.isAndroid) return;
    if (!initialized) return;

    await methodChannel.invokeMethod('setVideoFrameRate', {'fps': fps, 'duration': durationMs});
  }

  @override
  Future<void> clearVideoFrameRate() async {
    checkDisposed();
    if (!Platform.isAndroid) return;
    if (!initialized) return;

    await methodChannel.invokeMethod('clearVideoFrameRate');
  }

  @override
  Future<bool> requestAudioFocus() async {
    checkDisposed();
    if (!Platform.isAndroid) return true;
    if (!initialized) return false;

    final result = await methodChannel.invokeMethod<bool>('requestAudioFocus');
    return result ?? false;
  }

  @override
  Future<void> abandonAudioFocus() async {
    checkDisposed();
    if (!Platform.isAndroid) return;
    if (!initialized) return;

    await methodChannel.invokeMethod('abandonAudioFocus');
  }
}
