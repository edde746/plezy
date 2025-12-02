import 'dart:async';

import 'package:flutter/services.dart';

import '../models/audio_device.dart';
import '../models/audio_track.dart';
import '../models/player_log.dart';
import '../models/media.dart';
import '../models/subtitle_track.dart';
import '../models/track_selection.dart';
import '../models/tracks.dart';
import 'player.dart';
import 'player_state.dart';
import 'player_streams.dart';

/// Shared native implementation of [Player] for iOS and macOS.
/// Uses MPVKit via platform channels with Metal rendering.
class PlayerNative implements Player {
  static const _methodChannel = MethodChannel('com.plezy/mpv_player');
  static const _eventChannel = EventChannel('com.plezy/mpv_player/events');

  PlayerState _state = const PlayerState();

  @override
  PlayerState get state => _state;

  late final PlayerStreams _streams;

  @override
  PlayerStreams get streams => _streams;

  @override
  int? get textureId => null; // Uses direct Metal layer, not Flutter texture

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
  final _audioDevicesController =
      StreamController<List<AudioDevice>>.broadcast();

  StreamSubscription? _eventSubscription;
  bool _disposed = false;
  bool _initialized = false;
  bool _isVisible = false;

  PlayerNative() {
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
    );

    _setupEventListener();
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
      _handleMpvEvent(name, event['data'] as Map?);
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
        if (value is List) {
          final tracks = _parseTrackList(value);
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

  void _handleMpvEvent(String name, Map? data) {
    switch (name) {
      case 'end-file':
        final reason = data?['reason'] as String?;
        if (reason == 'eof') {
          _state = _state.copyWith(completed: true);
          _completedController.add(true);
        } else if (reason == 'error') {
          _errorController.add('Playback error');
        }
        break;

      case 'file-loaded':
        // Reset completed state when new file is loaded
        _state = _state.copyWith(completed: false);
        _completedController.add(false);
        break;
    }
  }

  Tracks _parseTrackList(List trackList) {
    final audioTracks = <AudioTrack>[];
    final subtitleTracks = <SubtitleTrack>[];

    for (final track in trackList) {
      if (track is! Map) continue;

      final type = track['type'] as String?;
      final id = track['id']?.toString() ?? '';

      if (type == 'audio') {
        audioTracks.add(AudioTrack(
          id: id,
          title: track['title'] as String?,
          language: track['lang'] as String?,
          codec: track['codec'] as String?,
          channels: (track['demux-channel-count'] as num?)?.toInt(),
          sampleRate: (track['demux-samplerate'] as num?)?.toInt(),
          isDefault: track['default'] as bool? ?? false,
        ));
      } else if (type == 'sub') {
        subtitleTracks.add(SubtitleTrack(
          id: id,
          title: track['title'] as String?,
          language: track['lang'] as String?,
          codec: track['codec'] as String?,
          isExternal: track['external'] as bool? ?? false,
          uri: track['external-filename'] as String?,
        ));
      }
    }

    return Tracks(audio: audioTracks, subtitle: subtitleTracks);
  }

  void _updateSelectedAudioTrack(dynamic trackId) {
    final id = trackId?.toString();
    AudioTrack? selectedTrack;

    if (id != null && id != 'no') {
      selectedTrack = _state.tracks.audio.cast<AudioTrack?>().firstWhere(
            (t) => t?.id == id,
            orElse: () => null,
          );
    }

    _state = _state.copyWith(
      track: _state.track.copyWith(audio: selectedTrack),
    );
    _trackController.add(_state.track);
  }

  void _updateSelectedSubtitleTrack(dynamic trackId) {
    final id = trackId?.toString();
    SubtitleTrack? selectedTrack;

    if (id != null && id != 'no') {
      selectedTrack =
          _state.tracks.subtitle.cast<SubtitleTrack?>().firstWhere(
                (t) => t?.id == id,
                orElse: () => null,
              );
    }

    _state = _state.copyWith(
      track: _state.track.copyWith(subtitle: selectedTrack),
    );
    _trackController.add(_state.track);
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    try {
      final result = await _methodChannel.invokeMethod<bool>('initialize');
      _initialized = result == true;
      if (!_initialized) {
        throw Exception('Failed to initialize player');
      }

      // Subscribe to MPV properties
      await _observeProperty('time-pos', 'double');
      await _observeProperty('duration', 'double');
      await _observeProperty('pause', 'flag');
      await _observeProperty('paused-for-cache', 'flag');
      await _observeProperty('track-list', 'node');
      await _observeProperty('eof-reached', 'flag');
      await _observeProperty('volume', 'double');
      await _observeProperty('aid', 'string');
      await _observeProperty('sid', 'string');
    } catch (e) {
      _errorController.add('Initialization failed: $e');
      rethrow;
    }
  }

  Future<void> _observeProperty(String name, String format) async {
    await _methodChannel.invokeMethod('observeProperty', {
      'name': name,
      'format': format,
    });
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
    await _methodChannel.invokeMethod('setVisible', {'visible': true});
    _isVisible = true;

    // Set start position if provided (must be set before loading file)
    if (media.start != null && media.start!.inSeconds > 0) {
      await setProperty('start', media.start!.inSeconds.toString());
    } else {
      // Reset start position if not resuming
      await setProperty('start', 'none');
    }

    await command(['loadfile', media.uri, 'replace']);
    if (!play) {
      await setProperty('pause', 'yes');
    }
  }

  @override
  Future<void> play() async {
    _checkDisposed();
    await setProperty('pause', 'no');
  }

  @override
  Future<void> pause() async {
    _checkDisposed();
    await setProperty('pause', 'yes');
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
    await command(['stop']);
    await _methodChannel.invokeMethod('setVisible', {'visible': false});
    _isVisible = false;
  }

  @override
  Future<void> seek(Duration position) async {
    _checkDisposed();
    await command([
      'seek',
      (position.inMilliseconds / 1000.0).toString(),
      'absolute',
    ]);
  }

  // ============================================
  // Track Selection
  // ============================================

  @override
  Future<void> selectAudioTrack(AudioTrack track) async {
    _checkDisposed();
    await setProperty('aid', track.id);
  }

  @override
  Future<void> selectSubtitleTrack(SubtitleTrack track) async {
    _checkDisposed();
    await setProperty('sid', track.id);
  }

  @override
  Future<void> addSubtitleTrack({
    required String uri,
    String? title,
    String? language,
    bool select = false,
  }) async {
    _checkDisposed();
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
    _checkDisposed();
    await setProperty('volume', volume.toString());
  }

  @override
  Future<void> setRate(double rate) async {
    _checkDisposed();
    await setProperty('speed', rate.toString());
  }

  @override
  Future<void> setAudioDevice(AudioDevice device) async {
    _checkDisposed();
    await setProperty('audio-device', device.name);
  }

  // ============================================
  // MPV Properties
  // ============================================

  @override
  Future<void> setProperty(String name, String value) async {
    _checkDisposed();
    await _ensureInitialized();
    await _methodChannel.invokeMethod('setProperty', {
      'name': name,
      'value': value,
    });
  }

  @override
  Future<String?> getProperty(String name) async {
    _checkDisposed();
    await _ensureInitialized();
    return await _methodChannel.invokeMethod<String>('getProperty', {
      'name': name,
    });
  }

  @override
  Future<void> command(List<String> args) async {
    _checkDisposed();
    await _ensureInitialized();
    await _methodChannel.invokeMethod('command', {'args': args});
  }

  // ============================================
  // Passthrough
  // ============================================

  @override
  Future<void> setAudioPassthrough(bool enabled) async {
    _checkDisposed();
    if (enabled) {
      await setProperty('audio-spdif', 'ac3,eac3,dts,dts-hd,truehd');
      await setProperty('audio-exclusive', 'yes');
    } else {
      await setProperty('audio-spdif', '');
      await setProperty('audio-exclusive', 'no');
    }
  }

  // ============================================
  // Visibility
  // ============================================

  @override
  Future<bool> setVisible(bool visible) async {
    _checkDisposed();

    try {
      await _methodChannel.invokeMethod('setVisible', {'visible': visible});
      _isVisible = visible;
      return true;
    } catch (e) {
      _errorController.add('Failed to set visibility: $e');
      return false;
    }
  }

  @override
  Future<void> setControlsVisible(bool visible) async {
    // No-op on most platforms. Override on Linux for transparency workaround.
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
  }
}
