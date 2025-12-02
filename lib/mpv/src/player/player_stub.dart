import 'dart:async';

import '../models/audio_device.dart';
import '../models/media.dart';
import '../models/audio_track.dart';
import '../models/subtitle_track.dart';
import '../models/tracks.dart';
import '../models/track_selection.dart';
import '../models/player_log.dart';
import 'player.dart';
import 'player_state.dart';
import 'player_streams.dart';

/// Stub implementation of [Player].
///
/// This implementation creates all the necessary stream controllers and
/// state management, but throws [UnimplementedError] for all playback
/// methods. It serves as a foundation for platform-specific implementations.
class PlayerStub implements Player {
  PlayerState _state = const PlayerState();

  @override
  PlayerState get state => _state;

  late final PlayerStreams _streams;

  @override
  PlayerStreams get streams => _streams;

  @override
  int? get textureId => null; // Set by platform implementation

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

  bool _disposed = false;

  PlayerStub() {
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
    throw UnimplementedError('Player.open() is not yet implemented');
  }

  @override
  Future<void> play() async {
    _checkDisposed();
    throw UnimplementedError('Player.play() is not yet implemented');
  }

  @override
  Future<void> pause() async {
    _checkDisposed();
    throw UnimplementedError('Player.pause() is not yet implemented');
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
    throw UnimplementedError('Player.stop() is not yet implemented');
  }

  @override
  Future<void> seek(Duration position) async {
    _checkDisposed();
    throw UnimplementedError('Player.seek() is not yet implemented');
  }

  // ============================================
  // Track Selection
  // ============================================

  @override
  Future<void> selectAudioTrack(AudioTrack track) async {
    _checkDisposed();
    throw UnimplementedError(
        'Player.selectAudioTrack() is not yet implemented');
  }

  @override
  Future<void> selectSubtitleTrack(SubtitleTrack track) async {
    _checkDisposed();
    throw UnimplementedError(
        'Player.selectSubtitleTrack() is not yet implemented');
  }

  @override
  Future<void> addSubtitleTrack({
    required String uri,
    String? title,
    String? language,
    bool select = false,
  }) async {
    _checkDisposed();
    throw UnimplementedError(
        'Player.addSubtitleTrack() is not yet implemented');
  }

  // ============================================
  // Volume and Rate
  // ============================================

  @override
  Future<void> setVolume(double volume) async {
    _checkDisposed();
    throw UnimplementedError('Player.setVolume() is not yet implemented');
  }

  @override
  Future<void> setRate(double rate) async {
    _checkDisposed();
    throw UnimplementedError('Player.setRate() is not yet implemented');
  }

  @override
  Future<void> setAudioDevice(AudioDevice device) async {
    _checkDisposed();
    throw UnimplementedError(
        'Player.setAudioDevice() is not yet implemented');
  }

  // ============================================
  // MPV Properties
  // ============================================

  @override
  Future<void> setProperty(String name, String value) async {
    _checkDisposed();
    throw UnimplementedError('Player.setProperty() is not yet implemented');
  }

  @override
  Future<String?> getProperty(String name) async {
    _checkDisposed();
    throw UnimplementedError('Player.getProperty() is not yet implemented');
  }

  @override
  Future<void> command(List<String> args) async {
    _checkDisposed();
    throw UnimplementedError('Player.command() is not yet implemented');
  }

  // ============================================
  // Passthrough
  // ============================================

  @override
  Future<void> setAudioPassthrough(bool enabled) async {
    _checkDisposed();
    throw UnimplementedError(
        'Player.setAudioPassthrough() is not yet implemented');
  }

  // ============================================
  // Visibility
  // ============================================

  @override
  Future<bool> setVisible(bool visible) async {
    _checkDisposed();
    // No-op on unsupported platforms
    return false;
  }

  @override
  Future<void> setControlsVisible(bool visible) async {
    // No-op on unsupported platforms
  }

  // ============================================
  // Lifecycle
  // ============================================

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

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
