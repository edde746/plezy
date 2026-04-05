import 'dart:io' show Platform;

import 'package:flutter/services.dart';

import '../models.dart';
import '../../utils/app_logger.dart';
import 'player_base.dart';

/// Shared native implementation of [Player] for iOS, macOS, Android (MPV fallback), and Linux.
/// Uses MPVKit via platform channels with Metal rendering (Apple), native window (Android),
/// or FlTextureGL (Linux).
class PlayerNative extends PlayerBase {
  int? _textureIdValue;
  Duration _serverManagedStartOffset = Duration.zero;

  bool _isPlexServerManagedStartUri(String uri) {
    try {
      final parsed = Uri.parse(uri);
      final path = parsed.path;
      final protocol = parsed.queryParameters['protocol']?.toLowerCase();
      return protocol == 'hls' &&
          (path.contains('/video/:/transcode/universal/start') ||
              path.contains('/video/:/transcode/universal/session/'));
    } catch (_) {
      return uri.contains('protocol=hls') &&
          (uri.contains('/video/:/transcode/universal/start') ||
              uri.contains('/video/:/transcode/universal/session/'));
    }
  }

  Duration _toNativePosition(Duration requestedPosition) {
    if (_serverManagedStartOffset <= Duration.zero) {
      return requestedPosition;
    }

    final normalized = requestedPosition - _serverManagedStartOffset;
    return normalized.isNegative ? Duration.zero : normalized;
  }

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

  // ============================================
  // Initialization
  // ============================================

  @override
  void handlePropertyChange(String name, dynamic value) {
    if (_serverManagedStartOffset > Duration.zero && value is num) {
      final offsetSeconds = _serverManagedStartOffset.inMilliseconds / 1000.0;
      switch (name) {
        case 'time-pos':
        case 'duration':
        case 'demuxer-cache-time':
          super.handlePropertyChange(name, value + offsetSeconds);
          return;
      }
    }

    super.handlePropertyChange(name, value);
  }

  Future<void> _ensureInitialized() async {
    if (initialized) return;

    try {
      final result = await invoke<Object>('initialize');
      if (result is int) {
        // Linux: initialize returns the texture ID
        _textureIdValue = result;
        initialized = true;
      } else {
        initialized = result == true;
      }
      if (!initialized) {
        throw Exception('Failed to initialize player');
      }

      // Subscribe to MPV properties
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
    } catch (e) {
      errorController.add('Initialization failed: $e');
      rethrow;
    }
  }

  // ============================================
  // Playback Control
  // ============================================

  /// Opens a content:// URI via the platform channel and returns the raw FD number.
  /// Returns null if the call fails.
  Future<int?> _openContentFd(String contentUri) async {
    try {
      return await invoke<int>('openContentFd', {'uri': contentUri});
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> open(Media media, {bool play = true, bool isLive = false, List<SubtitleTrack>? externalSubtitles}) async {
    if (disposed) return;
    await _ensureInitialized();
    setSeekable(false);

    // Show the video layer
    await setVisible(true);

    // Set HTTP headers for Plex authentication and profile
    if (media.headers != null && media.headers!.isNotEmpty) {
      final headerList = media.headers!.entries.map((e) => '${e.key}: ${e.value}').toList();
      await setProperty('http-header-fields', headerList.join(','));
    }

    // Plex HLS transcode URLs already honor offset server-side.
    // Applying MPV's local start on top of that can leave playback stuck
    // on a black frame while the server keeps transcoding.
    final requestedStart = media.start ?? Duration.zero;
    final usesServerManagedStart =
        requestedStart > Duration.zero && _isPlexServerManagedStartUri(media.uri);
    _serverManagedStartOffset = usesServerManagedStart ? requestedStart : Duration.zero;

    // Set start position if provided (must be set before loading file)
    if (requestedStart > Duration.zero && !usesServerManagedStart) {
      await setProperty('start', requestedStart.inSeconds.toString());
    } else {
      // Reset start position if not resuming
      await setProperty('start', 'none');
    }

    // Set pause BEFORE loadfile to prevent decoder from starting immediately.
    // This is important for adding external subtitles before playback begins,
    // avoiding a race condition that can freeze the video decoder on Android (issue #226).
    await setProperty('pause', play ? 'no' : 'yes');

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
    _serverManagedStartOffset = Duration.zero;
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      final nativePosition = _toNativePosition(position);
      await command(['seek', (nativePosition.inMilliseconds / 1000.0).toString(), 'absolute']);
    } on PlatformException catch (e) {
      if (e.code == 'COMMAND_FAILED' || e.code == 'NOT_INITIALIZED') {
        appLogger.w('Seek failed (${e.code}), player not ready');
        return;
      }
      rethrow;
    }
  }

  // ============================================
  // Track Selection
  // ============================================

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

  // ============================================
  // Volume and Rate
  // ============================================

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

  // ============================================
  // MPV Properties
  // ============================================

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

  // ============================================
  // Log Level
  // ============================================

  @override
  Future<void> setLogLevel(String level) async {
    if (disposed) return;
    await _ensureInitialized();
    await invoke('setLogLevel', {'level': level});
  }

  // ============================================
  // Passthrough
  // ============================================

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

  // ============================================
  // Platform-Specific Overrides
  // ============================================

  @override
  Future<void> updateFrame() async {
    if (disposed || !initialized) return;
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isLinux) {
      await invoke('updateFrame');
    }
  }

  @override
  Future<void> setVideoFrameRate(double fps, int durationMs) async {
    if (!Platform.isAndroid || disposed || !initialized) return;
    await invoke('setVideoFrameRate', {'fps': fps, 'duration': durationMs});
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
