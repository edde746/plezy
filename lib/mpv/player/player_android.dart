import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import '../../utils/app_logger.dart';
import '../models.dart';
import 'player.dart';
import 'player_state.dart';
import 'player_streams.dart';

/// Android implementation of [Player] using ExoPlayer.
/// Provides hardware-accelerated playback with ASS subtitle support via libass-android.
class PlayerAndroid implements Player {
  static const _methodChannel = MethodChannel('com.plezy/exo_player');
  static const _eventChannel = EventChannel('com.plezy/exo_player/events');

  PlayerState _state = const PlayerState();

  @override
  PlayerState get state => _state;

  late final PlayerStreams _streams;

  @override
  PlayerStreams get streams => _streams;

  @override
  int? get textureId => null; // Uses SurfaceView, not Flutter texture

  @override
  String get playerType => 'exoplayer';

  // Stream controllers
  final _playingController = StreamController<bool>.broadcast();
  final _completedController = StreamController<bool>.broadcast();
  final _bufferingController = StreamController<bool>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();
  final _bufferController = StreamController<Duration>.broadcast();
  final _volumeController = StreamController<double>.broadcast();
  final _rateController = StreamController<double>.broadcast();
  final _tracksController = StreamController<Tracks>.broadcast();
  final _trackController = StreamController<TrackSelection>.broadcast();
  final _logController = StreamController<PlayerLog>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _audioDeviceController = StreamController<AudioDevice>.broadcast();
  final _audioDevicesController = StreamController<List<AudioDevice>>.broadcast();
  final _playbackRestartController = StreamController<void>.broadcast();
  final _backendSwitchedController = StreamController<void>.broadcast();

  StreamSubscription? _eventSubscription;
  bool _disposed = false;
  bool _initialized = false;

  PlayerAndroid() {
    _streams = PlayerStreams(
      playing: _playingController.stream,
      completed: _completedController.stream,
      buffering: _bufferingController.stream,
      position: _positionController.stream,
      duration: _durationController.stream,
      buffer: _bufferController.stream,
      volume: _volumeController.stream,
      rate: _rateController.stream,
      tracks: _tracksController.stream,
      track: _trackController.stream,
      log: _logController.stream,
      error: _errorController.stream,
      audioDevice: _audioDeviceController.stream,
      audioDevices: _audioDevicesController.stream,
      playbackRestart: _playbackRestartController.stream,
      backendSwitched: _backendSwitchedController.stream,
    );

    _setupEventListener();

    // Forward logs to app logger
    _logController.stream.listen(_forwardToAppLogger);
  }

  void _forwardToAppLogger(PlayerLog log) {
    final message = '[ExoPlayer:${log.prefix}] ${log.text}'.trimRight();
    switch (log.level) {
      case PlayerLogLevel.fatal:
      case PlayerLogLevel.error:
        appLogger.e(message);
      case PlayerLogLevel.warn:
        appLogger.w(message);
      case PlayerLogLevel.info:
      case PlayerLogLevel.verbose:
        appLogger.i(message);
      case PlayerLogLevel.debug:
      case PlayerLogLevel.trace:
        appLogger.d(message);
      case PlayerLogLevel.none:
        break;
    }
  }

  void _setupEventListener() {
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      _handleEvent,
      onError: (error) {
        _errorController.add(error.toString());
      },
    );
  }

  void _handleEvent(dynamic event) {
    if (event is! Map) return;

    final type = event['type'] as String?;
    final name = event['name'] as String?;

    if (type == 'property' && name != null) {
      _handlePropertyChange(name, event['value']);
    } else if (type == 'event' && name != null) {
      _handlePlayerEvent(name, event['data'] as Map?);
    }
  }

  void _handlePropertyChange(String name, dynamic value) {
    switch (name) {
      case 'pause':
        final playing = value == false;
        _state = _state.copyWith(playing: playing);
        _playingController.add(playing);
        break;

      case 'eof-reached':
        final completed = value == true;
        _state = _state.copyWith(completed: completed);
        _completedController.add(completed);
        break;

      case 'paused-for-cache':
        final buffering = value == true;
        _state = _state.copyWith(buffering: buffering);
        _bufferingController.add(buffering);
        break;

      case 'time-pos':
        if (value is num) {
          final position = Duration(milliseconds: (value * 1000).toInt());
          _state = _state.copyWith(position: position);
          _positionController.add(position);
        }
        break;

      case 'duration':
        if (value is num) {
          final duration = Duration(milliseconds: (value * 1000).toInt());
          _state = _state.copyWith(duration: duration);
          _durationController.add(duration);
        }
        break;

      case 'demuxer-cache-time':
        if (value is num) {
          final buffer = Duration(milliseconds: (value * 1000).toInt());
          _state = _state.copyWith(buffer: buffer);
          _bufferController.add(buffer);
        }
        break;

      case 'volume':
        if (value is num) {
          final volume = value.toDouble();
          _state = _state.copyWith(volume: volume);
          _volumeController.add(volume);
        }
        break;

      case 'speed':
        if (value is num) {
          final rate = value.toDouble();
          _state = _state.copyWith(rate: rate);
          _rateController.add(rate);
        }
        break;

      case 'track-list':
        List? trackList;
        if (value is List) {
          trackList = value;
        } else if (value is String && value.isNotEmpty) {
          // MPV sends track-list as JSON string after fallback
          try {
            final parsed = jsonDecode(value);
            if (parsed is List) trackList = parsed;
          } catch (_) {
            // Ignore parse errors
          }
        }
        if (trackList != null) {
          final tracks = _parseTrackList(trackList);
          _state = _state.copyWith(tracks: tracks);
          _tracksController.add(tracks);
        }
        break;

      case 'aid':
        _updateSelectedAudioTrack(value);
        break;

      case 'sid':
        _updateSelectedSubtitleTrack(value);
        break;
    }
  }

  void _handlePlayerEvent(String name, Map? data) {
    switch (name) {
      case 'end-file':
        final reason = data?['reason'] as String?;
        if (reason == 'eof') {
          _state = _state.copyWith(completed: true);
          _completedController.add(true);
        } else if (reason == 'error') {
          _errorController.add(data?['message'] as String? ?? 'Playback error');
        }
        break;

      case 'file-loaded':
        _state = _state.copyWith(completed: false);
        _completedController.add(false);
        break;

      case 'playback-restart':
        _playbackRestartController.add(null);
        break;

      case 'backend-switched':
        // Native player switched from ExoPlayer to MPV due to unsupported format
        _backendSwitchedController.add(null);
        break;

      case 'log-message':
        final prefix = data?['prefix'] as String? ?? '';
        final levelStr = data?['level'] as String? ?? 'info';
        final text = data?['text'] as String? ?? '';
        final level = _parseLogLevel(levelStr);
        _logController.add(PlayerLog(level: level, prefix: prefix, text: text));
        break;
    }
  }

  PlayerLogLevel _parseLogLevel(String level) {
    return switch (level) {
      'fatal' => PlayerLogLevel.fatal,
      'error' => PlayerLogLevel.error,
      'warn' => PlayerLogLevel.warn,
      'info' => PlayerLogLevel.info,
      'v' || 'verbose' => PlayerLogLevel.verbose,
      'debug' => PlayerLogLevel.debug,
      'trace' => PlayerLogLevel.trace,
      _ => PlayerLogLevel.info,
    };
  }

  Tracks _parseTrackList(List trackList) {
    final audioTracks = <AudioTrack>[];
    final subtitleTracks = <SubtitleTrack>[];

    for (final track in trackList) {
      if (track is! Map) continue;

      final type = track['type'] as String?;
      final id = track['id']?.toString() ?? '';

      if (type == 'audio') {
        audioTracks.add(
          AudioTrack(
            id: id,
            title: track['title'] as String?,
            language: track['lang'] as String?,
            codec: track['codec'] as String?,
            channels: (track['demux-channel-count'] as num?)?.toInt(),
            sampleRate: (track['demux-samplerate'] as num?)?.toInt(),
            isDefault: track['default'] as bool? ?? false,
          ),
        );
      } else if (type == 'sub') {
        subtitleTracks.add(
          SubtitleTrack(
            id: id,
            title: track['title'] as String?,
            language: track['lang'] as String?,
            codec: track['codec'] as String?,
            isExternal: track['external'] as bool? ?? false,
            uri: track['external-filename'] as String?,
          ),
        );
      }
    }

    return Tracks(audio: audioTracks, subtitle: subtitleTracks);
  }

  void _updateSelectedAudioTrack(dynamic trackId) {
    final id = trackId?.toString();
    AudioTrack? selectedTrack;

    if (id != null && id != 'no') {
      selectedTrack = _state.tracks.audio.cast<AudioTrack?>().firstWhere((t) => t?.id == id, orElse: () => null);
    }

    _state = _state.copyWith(track: _state.track.copyWith(audio: selectedTrack));
    _trackController.add(_state.track);
  }

  void _updateSelectedSubtitleTrack(dynamic trackId) {
    final id = trackId?.toString();
    SubtitleTrack? selectedTrack;

    if (id == null || id == 'no') {
      selectedTrack = SubtitleTrack.off;
    } else {
      selectedTrack = _state.tracks.subtitle.cast<SubtitleTrack?>().firstWhere((t) => t?.id == id, orElse: () => null);
    }

    _state = _state.copyWith(track: _state.track.copyWith(subtitle: selectedTrack));
    _trackController.add(_state.track);
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    try {
      final result = await _methodChannel.invokeMethod<bool>('initialize');
      _initialized = result == true;
      if (!_initialized) {
        throw Exception('Failed to initialize ExoPlayer');
      }
    } catch (e) {
      _errorController.add('Initialization failed: $e');
      rethrow;
    }
  }

  void _checkDisposed() {
    if (_disposed) {
      throw StateError('Player has been disposed');
    }
  }

  // ============================================
  // Playback Control
  // ============================================

  @override
  Future<void> open(Media media, {bool play = true}) async {
    _checkDisposed();
    await _ensureInitialized();

    // Show the video layer
    await setVisible(true);

    await _methodChannel.invokeMethod('open', {
      'uri': media.uri,
      'headers': media.headers,
      'startPositionMs': media.start?.inMilliseconds ?? 0,
      'autoPlay': play,
    });
  }

  @override
  Future<void> play() async {
    _checkDisposed();
    await _methodChannel.invokeMethod('play');
  }

  @override
  Future<void> pause() async {
    _checkDisposed();
    await _methodChannel.invokeMethod('pause');
  }

  @override
  Future<void> playOrPause() async {
    _checkDisposed();
    if (_state.playing) {
      await pause();
    } else {
      await play();
    }
  }

  @override
  Future<void> stop() async {
    _checkDisposed();
    await _methodChannel.invokeMethod('stop');
    await setVisible(false);
  }

  @override
  Future<void> seek(Duration position) async {
    _checkDisposed();
    await _methodChannel.invokeMethod('seek', {'positionMs': position.inMilliseconds});
  }

  // ============================================
  // Track Selection
  // ============================================

  @override
  Future<void> selectAudioTrack(AudioTrack track) async {
    _checkDisposed();
    await _methodChannel.invokeMethod('selectAudioTrack', {'trackId': track.id});
  }

  @override
  Future<void> selectSubtitleTrack(SubtitleTrack track) async {
    _checkDisposed();
    await _methodChannel.invokeMethod('selectSubtitleTrack', {'trackId': track.id});
  }

  @override
  Future<void> addSubtitleTrack({required String uri, String? title, String? language, bool select = false}) async {
    _checkDisposed();
    await _methodChannel.invokeMethod('addSubtitleTrack', {
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
    _checkDisposed();
    await _methodChannel.invokeMethod('setVolume', {'volume': volume});
  }

  @override
  Future<void> setRate(double rate) async {
    _checkDisposed();
    await _methodChannel.invokeMethod('setRate', {'rate': rate});
  }

  @override
  Future<void> setAudioDevice(AudioDevice device) async {
    // ExoPlayer doesn't support audio device selection on Android
    // This is a no-op
  }

  // ============================================
  // MPV Properties (Compatibility Layer)
  // ============================================

  @override
  Future<void> setProperty(String name, String value) async {
    _checkDisposed();
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
      // Other properties are no-ops for ExoPlayer
      default:
        // No-op for MPV-specific properties
        break;
    }
  }

  @override
  Future<String?> getProperty(String name) async {
    _checkDisposed();
    // Return state-based values for common properties
    switch (name) {
      case 'pause':
        return _state.playing ? 'no' : 'yes';
      case 'volume':
        return _state.volume.toString();
      case 'speed':
        return _state.rate.toString();
      case 'time-pos':
        return (_state.position.inMilliseconds / 1000.0).toString();
      case 'duration':
        return (_state.duration.inMilliseconds / 1000.0).toString();
      default:
        return null;
    }
  }

  /// Get all playback stats from ExoPlayer.
  /// Returns a map with video/audio codec info, buffer state, and performance metrics.
  Future<Map<String, dynamic>> getStats() async {
    _checkDisposed();
    try {
      final result = await _methodChannel.invokeMethod<Map>('getStats');
      return Map<String, dynamic>.from(result ?? {});
    } catch (e) {
      return {};
    }
  }

  /// Get the current player type ('exoplayer' or 'mpv' if fallback is active).
  Future<String> getPlayerType() async {
    _checkDisposed();
    try {
      final result = await _methodChannel.invokeMethod<String>('getPlayerType');
      return result ?? 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  @override
  Future<void> command(List<String> args) async {
    _checkDisposed();
    // Handle MPV commands by translating to ExoPlayer equivalents
    if (args.isEmpty) return;

    switch (args[0]) {
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
            final newPos = _state.position + Duration(milliseconds: (seconds * 1000).toInt());
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
      // Other commands are no-ops
    }
  }

  // ============================================
  // Passthrough (Not supported by ExoPlayer)
  // ============================================

  @override
  Future<void> setAudioPassthrough(bool enabled) async {
    // ExoPlayer doesn't support direct audio passthrough configuration
    // This is handled by the device's audio settings
  }

  // ============================================
  // Visibility
  // ============================================

  @override
  Future<bool> setVisible(bool visible) async {
    _checkDisposed();

    try {
      await _methodChannel.invokeMethod('setVisible', {'visible': visible});
      return true;
    } catch (e) {
      _errorController.add('Failed to set visibility: $e');
      return false;
    }
  }

  @override
  Future<void> updateFrame() async {
    // Not needed for ExoPlayer on Android
  }

  // ============================================
  // Frame Rate Matching
  // ============================================

  @override
  Future<void> setVideoFrameRate(double fps, int durationMs) async {
    _checkDisposed();
    if (!_initialized) return;

    await _methodChannel.invokeMethod('setVideoFrameRate', {'fps': fps, 'duration': durationMs});
  }

  @override
  Future<void> clearVideoFrameRate() async {
    _checkDisposed();
    if (!_initialized) return;

    await _methodChannel.invokeMethod('clearVideoFrameRate');
  }

  // ============================================
  // Audio Focus
  // ============================================

  @override
  Future<bool> requestAudioFocus() async {
    _checkDisposed();
    if (!_initialized) return false;

    final result = await _methodChannel.invokeMethod<bool>('requestAudioFocus');
    return result ?? false;
  }

  @override
  Future<void> abandonAudioFocus() async {
    _checkDisposed();
    if (!_initialized) return;

    await _methodChannel.invokeMethod('abandonAudioFocus');
  }

  // ============================================
  // Lifecycle
  // ============================================

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    await _eventSubscription?.cancel();
    await _methodChannel.invokeMethod('dispose');

    await _playingController.close();
    await _completedController.close();
    await _bufferingController.close();
    await _positionController.close();
    await _durationController.close();
    await _bufferController.close();
    await _volumeController.close();
    await _rateController.close();
    await _tracksController.close();
    await _trackController.close();
    await _logController.close();
    await _errorController.close();
    await _audioDeviceController.close();
    await _audioDevicesController.close();
    await _playbackRestartController.close();
    await _backendSwitchedController.close();
  }
}
