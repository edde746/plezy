import 'dart:io' show Platform;

import 'package:flutter/services.dart';

import '../models.dart';
import 'player_base.dart';

/// Shared native implementation of [Player] for iOS, macOS, Android (MPV fallback), and Linux.
/// Uses MPVKit via platform channels with Metal rendering (Apple), native window (Android),
/// or FlTextureGL (Linux).
class PlayerNative extends PlayerBase {
  int? _textureIdValue;

  @override
  int? get textureId => _textureIdValue;

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

  /// Node properties are returned as structured maps on macOS/iOS/Linux,
  /// but as JSON strings on Android/Windows.
  static final String _nodeFormat = (Platform.isAndroid || Platform.isWindows) ? 'string' : 'node';

  // Memoizes the in-flight init Future so concurrent callers (e.g. the
  // parallel `requestAudioFocus()` and `setProperty()` paths kicked off in
  // VideoPlayerScreen._initializePlayer) share one `invoke('initialize')`.
  // Two concurrent invokes on Android caused MpvPlayerPlugin.handleInitialize
  // to dispose-and-recreate the in-flight core, hanging playback (#930).
  Future<void>? _initFuture;

  Future<void> _ensureInitialized() async {
    if (initialized) return;
    return _initFuture ??= _doInitialize();
  }

  Future<void> _doInitialize() async {
    try {
      final result = await invoke<Object>('initialize');
      final bool ok;
      if (result is int) {
        // Linux: initialize returns the texture ID
        _textureIdValue = result;
        ok = true;
      } else {
        ok = result == true;
      }
      if (!ok) {
        throw Exception('Failed to initialize player');
      }

      // Subscribe to MPV properties before flipping `initialized` so partial
      // failures don't leave us in a half-initialized state that the memoized
      // future would falsely treat as ready.
      await observeProperty('time-pos', 'double');
      await observeProperty('duration', 'double');
      await observeProperty('seekable', 'flag');
      await observeProperty('pause', 'flag');
      await observeProperty('paused-for-cache', 'flag');
      await observeProperty('track-list', _nodeFormat);
      await observeProperty('eof-reached', 'flag');
      await observeProperty('volume', 'double');
      await observeProperty('speed', 'double');
      await observeProperty('aid', 'string');
      await observeProperty('sid', 'string');
      await observeProperty('secondary-sid', 'string');
      await observeProperty('demuxer-cache-state', _nodeFormat);
      await observeProperty('audio-device-list', _nodeFormat);
      await observeProperty('audio-device', 'string');

      initialized = true;
    } catch (e) {
      _initFuture = null;
      errorController.add(PlayerError('Initialization failed: $e'));
      rethrow;
    }
  }

  Future<int?> _openContentFd(String contentUri) async {
    try {
      return await invoke<int>('openContentFd', {'uri': contentUri});
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> open(
    Media media, {
    bool play = true,
    bool isLive = false,
    List<SubtitleTrack>? externalSubtitles,
  }) async {
    if (disposed) return;
    await _ensureInitialized();
    setSeekable(false);

    await setVisible(true);

    if (media.headers != null && media.headers!.isNotEmpty) {
      final headerList = media.headers!.entries.map((e) => '${e.key}: ${e.value}').toList();
      await setProperty('http-header-fields', headerList.join(','));
    }

    // 'start' must be set before loadfile.
    if (media.start != null && media.start!.inSeconds > 0) {
      await setProperty('start', media.start!.inSeconds.toString());
    } else {
      await setProperty('start', 'none');
    }

    // Prevents race condition that can freeze the video decoder on Android (issue #226).
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
    await setProperty('pause', 'no');
  }

  @override
  Future<void> pause() async {
    await setProperty('pause', 'yes');
  }

  @override
  Future<void> stop() async {
    await command(['stop']);
    setSeekable(false);
    await invoke('setVisible', {'visible': false});
  }

  @override
  Future<void> seek(Duration position) async {
    await runSeek(() => command(['seek', (position.inMilliseconds / 1000.0).toString(), 'absolute']));
  }

  @override
  Future<void> selectAudioTrack(AudioTrack track) async {
    await setProperty('aid', track.id);
  }

  @override
  Future<void> selectSubtitleTrack(SubtitleTrack track) async {
    await setProperty('sid', track.id);
  }

  @override
  Future<void> selectSecondarySubtitleTrack(SubtitleTrack track) async {
    await setProperty('secondary-sid', track.id);
  }

  @override
  Future<void> addSubtitleTrack({required String uri, String? title, String? language, bool select = false}) async {
    final args = ['sub-add', uri, select ? 'select' : 'auto'];
    if (title != null) args.add('title=$title');
    if (language != null) args.add('lang=$language');
    await command(args);
  }

  @override
  Future<void> setVolume(double volume) async {
    await setProperty('volume', volume.toString());
  }

  @override
  Future<void> setRate(double rate) async {
    await setProperty('speed', rate.toString());
  }

  @override
  Future<void> setAudioDevice(AudioDevice device) async {
    await setProperty('audio-device', device.name);
  }

  @override
  Future<void> setProperty(String name, String value) async {
    if (disposed) return;
    await _ensureInitialized();
    await invoke('setProperty', {'name': name, 'value': value});
  }

  @override
  Future<String?> getProperty(String name) async {
    if (disposed) return null;
    await _ensureInitialized();
    return await invoke<String>('getProperty', {'name': name});
  }

  @override
  Future<void> command(List<String> args) async {
    if (disposed) return;
    await _ensureInitialized();
    await invoke('command', {'args': args});
  }

  @override
  Future<void> setLogLevel(String level) async {
    if (disposed) return;
    await _ensureInitialized();
    await invoke('setLogLevel', {'level': level});
  }

  @override
  Future<void> setAudioPassthrough(bool enabled) async {
    if (enabled) {
      await setProperty('audio-spdif', 'ac3,eac3,dts,dts-hd,truehd');
      await setProperty('audio-exclusive', 'yes');
    } else {
      await setProperty('audio-spdif', '');
      await setProperty('audio-exclusive', 'no');
    }
  }

  @override
  Future<void> updateFrame() async {
    if (disposed || !initialized) return;
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isLinux) {
      await invoke('updateFrame');
    }
  }

  @override
  Future<bool> setVideoFrameRate(double fps, int durationMs, {int extraDelayMs = 0}) async {
    if (!Platform.isAndroid || disposed || !initialized) return false;
    final result = await invoke<bool>('setVideoFrameRate', {
      'fps': fps,
      'duration': durationMs,
      'extraDelayMs': extraDelayMs,
    });
    return result ?? false;
  }

  @override
  Future<void> clearVideoFrameRate() async {
    if (!Platform.isAndroid || disposed || !initialized) return;
    await invoke('clearVideoFrameRate');
  }

  @override
  Future<bool> requestAudioFocus() async {
    if (disposed) return false;
    if (!Platform.isAndroid) return true;
    await _ensureInitialized();
    return await invoke<bool>('requestAudioFocus') ?? false;
  }

  @override
  Future<void> abandonAudioFocus() async {
    if (!Platform.isAndroid || disposed || !initialized) return;
    await invoke('abandonAudioFocus');
  }
}
