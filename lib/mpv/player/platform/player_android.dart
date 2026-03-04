import 'package:flutter/services.dart';

import '../../models.dart';
import '../player_base.dart';

/// Android implementation of [Player] using ExoPlayer.
/// Provides hardware-accelerated playback with ASS subtitle support via libass-android.
class PlayerAndroid extends PlayerBase {
  static const _methodChannel = MethodChannel('com.plezy/exo_player');
  static const _eventChannel = EventChannel('com.plezy/exo_player/events');

  int? _bufferSizeBytes;
  bool _tunnelingEnabled = true;

  /// Stored subtitle track ID when subtitles are hidden via sub-visibility.
  String? _hiddenSubtitleTrackId;

  @override
  MethodChannel get methodChannel => _methodChannel;

  @override
  EventChannel get eventChannel => _eventChannel;

  @override
  String get logPrefix => 'ExoPlayer';

  @override
  String get playerType => 'exoplayer';

  @override
  bool get supportsSecondarySubtitles => false;

  // ============================================
  // Platform-Specific Event Handling
  // ============================================

  @override
  void handlePlayerEvent(String name, Map? data) {
    // Handle Android-specific events
    if (name == 'backend-switched') {
      // Native player switched from ExoPlayer to MPV due to unsupported format
      backendSwitchedController.add(null);
      return;
    }

    // Delegate to base class for common events
    super.handlePlayerEvent(name, data);
  }

  // ============================================
  // Initialization
  // ============================================

  Future<void> _ensureInitialized() async {
    if (initialized) return;

    try {
      final result = await invoke<bool>('initialize', {
        'bufferSizeBytes': _bufferSizeBytes,
        'tunnelingEnabled': _tunnelingEnabled,
      });
      initialized = result == true;
      if (!initialized) {
        throw Exception('Failed to initialize ExoPlayer');
      }

      // Register property observers so the plugin knows propId mappings
      await observeProperty('time-pos', 'double');
      await observeProperty('duration', 'double');
      await observeProperty('pause', 'flag');
      await observeProperty('paused-for-cache', 'flag');
      await observeProperty('track-list', 'string');
      await observeProperty('eof-reached', 'flag');
      await observeProperty('volume', 'double');
      await observeProperty('speed', 'double');
      await observeProperty('aid', 'string');
      await observeProperty('sid', 'string');
      await observeProperty('demuxer-cache-time', 'double');
    } catch (e) {
      errorController.add('Initialization failed: $e');
      rethrow;
    }
  }

  // ============================================
  // Playback Control
  // ============================================

  @override
  Future<void> open(Media media, {bool play = true, bool isLive = false}) async {
    if (disposed) return;
    await _ensureInitialized();

    // Show the video layer
    await setVisible(true);

    await invoke('open', {
      'uri': media.uri,
      'headers': media.headers,
      'startPositionMs': media.start?.inMilliseconds ?? 0,
      'autoPlay': play,
      'isLive': isLive,
    });
  }

  @override
  Future<void> play() async {
    await invoke('play');
  }

  @override
  Future<void> pause() async {
    await invoke('pause');
  }

  @override
  Future<void> stop() async {
    await invoke('stop');
    await setVisible(false);
  }

  @override
  Future<void> seek(Duration position) async {
    await invoke('seek', {'positionMs': position.inMilliseconds});
  }

  // ============================================
  // Track Selection
  // ============================================

  @override
  Future<void> selectAudioTrack(AudioTrack track) async {
    await invoke('selectAudioTrack', {'trackId': track.id});
  }

  @override
  Future<void> selectSubtitleTrack(SubtitleTrack track) async {
    await invoke('selectSubtitleTrack', {'trackId': track.id});
  }

  @override
  Future<void> addSubtitleTrack({required String uri, String? title, String? language, bool select = false}) async {
    await invoke('addSubtitleTrack', {
      'uri': uri,
      'title': title,
      'language': language,
      'select': select,
    });
  }

  // ============================================
  // Volume and Rate
  // ============================================

  @override
  Future<void> setVolume(double volume) async {
    await invoke('setVolume', {'volume': volume});
  }

  @override
  Future<void> setRate(double rate) async {
    await invoke('setRate', {'rate': rate});
  }

  // ============================================
  // MPV Properties (Compatibility Layer)
  // ============================================

  @override
  Future<void> setProperty(String name, String value) async {
    if (disposed) return;
    // ExoPlayer doesn't use MPV properties, but we handle common ones
    switch (name) {
      case 'pause':
        if (value == 'yes') {
          await pause();
        } else {
          await play();
        }
        break;
      case 'volume':
        await setVolume(double.tryParse(value) ?? 100);
        break;
      case 'speed':
        await setRate(double.tryParse(value) ?? 1.0);
        break;
      case 'demuxer-max-bytes':
        _bufferSizeBytes = int.tryParse(value);
        break;
      case 'tunneled-playback':
        _tunnelingEnabled = value != 'no';
        break;
      case 'sub-visibility':
        if (value == 'no') {
          // Store current subtitle track and disable
          final current = state.track.subtitle;
          if (current != null && current.id != 'no') {
            _hiddenSubtitleTrackId = current.id;
            await selectSubtitleTrack(SubtitleTrack.off);
          }
        } else {
          // Restore previously hidden subtitle track
          final storedId = _hiddenSubtitleTrackId;
          if (storedId != null) {
            _hiddenSubtitleTrackId = null;
            final track = state.tracks.subtitle.cast<SubtitleTrack?>().firstWhere(
              (t) => t?.id == storedId,
              orElse: () => null,
            );
            if (track != null) {
              await selectSubtitleTrack(track);
            }
          }
        }
        break;
      // Other properties are no-ops for ExoPlayer
    }
  }

  @override
  Future<String?> getProperty(String name) async {
    if (disposed) return null;
    // Return state-based values for common properties
    switch (name) {
      case 'pause':
        return state.playing ? 'no' : 'yes';
      case 'volume':
        return state.volume.toString();
      case 'speed':
        return state.rate.toString();
      case 'time-pos':
        return (state.position.inMilliseconds / 1000.0).toString();
      case 'duration':
        return (state.duration.inMilliseconds / 1000.0).toString();
      // Video dimensions - query from ExoPlayer stats
      case 'width':
      case 'dwidth':
        final stats = await getStats();
        final width = stats['videoWidth'];
        return width?.toString();
      case 'height':
      case 'dheight':
        final stats = await getStats();
        final height = stats['videoHeight'];
        return height?.toString();
      default:
        return null;
    }
  }

  /// Get all playback stats from ExoPlayer.
  /// Returns a map with video/audio codec info, buffer state, and performance metrics.
  Future<Map<String, dynamic>> getStats() async {
    if (disposed) return {};
    try {
      final result = await invoke<Map>('getStats');
      return Map<String, dynamic>.from(result ?? {});
    } catch (e) {
      return {};
    }
  }

  /// Get the device's large heap size in MB (Android only).
  /// Returns 0 if unavailable.
  static Future<int> getHeapSize() async {
    try {
      final result = await _methodChannel.invokeMethod<int>('getHeapSize');
      return result ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get the current player type ('exoplayer' or 'mpv' if fallback is active).
  Future<String> getPlayerType() async {
    if (disposed) return 'unknown';
    try {
      final result = await invoke<String>('getPlayerType');
      return result ?? 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  @override
  Future<void> command(List<String> args) async {
    if (disposed) return;
    // Handle MPV commands by translating to ExoPlayer equivalents
    if (args.isEmpty) return;

    switch (args.first) {
      case 'loadfile':
        if (args.length > 1) {
          await open(Media(args[1]));
        }
        break;
      case 'seek':
        if (args.length > 1) {
          final seconds = double.tryParse(args[1]) ?? 0;
          final mode = args.length > 2 ? args[2] : 'relative';
          if (mode == 'absolute') {
            await seek(Duration(milliseconds: (seconds * 1000).toInt()));
          } else {
            final newPos = state.position + Duration(milliseconds: (seconds * 1000).toInt());
            await seek(newPos);
          }
        }
        break;
      case 'stop':
        await stop();
        break;
      case 'sub-add':
        if (args.length > 1) {
          final select = args.length > 2 && args[2] == 'select';
          await addSubtitleTrack(uri: args[1], select: select);
        }
        break;
    }
  }

  // ============================================
  // Subtitle Styling (ExoPlayer Native)
  // ============================================

  /// Apply subtitle styling to the native ExoPlayer layer.
  ///
  /// For non-ASS subtitles, applies CaptionStyleCompat (color, border, background).
  /// For ASS subtitles, applies font scale via libass setFontScale().
  Future<void> setSubtitleStyle({
    required double fontSize,
    required String textColor,
    required double borderSize,
    required String borderColor,
    required String bgColor,
    required int bgOpacity,
    int subtitlePosition = 100,
  }) async {
    if (disposed || !initialized) return;
    await invoke('setSubtitleStyle', {
      'fontSize': fontSize,
      'textColor': textColor,
      'borderSize': borderSize,
      'borderColor': borderColor,
      'bgColor': bgColor,
      'bgOpacity': bgOpacity,
      'subtitlePosition': subtitlePosition,
    });
  }

  // ============================================
  // Frame Rate Matching
  // ============================================

  @override
  Future<void> setVideoFrameRate(double fps, int durationMs) async {
    if (disposed || !initialized) return;
    await invoke('setVideoFrameRate', {'fps': fps, 'duration': durationMs});
  }

  @override
  Future<void> clearVideoFrameRate() async {
    if (disposed || !initialized) return;
    await invoke('clearVideoFrameRate');
  }

  // ============================================
  // Audio Focus
  // ============================================

  @override
  Future<bool> requestAudioFocus() async {
    if (disposed) return false;
    await _ensureInitialized();
    return await invoke<bool>('requestAudioFocus') ?? false;
  }

  @override
  Future<void> abandonAudioFocus() async {
    if (disposed || !initialized) return;
    await invoke('abandonAudioFocus');
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
}
