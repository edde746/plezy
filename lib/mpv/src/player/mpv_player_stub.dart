import 'dart:async';

import '../models/mpv_audio_device.dart';
import '../models/mpv_media.dart';
import '../models/mpv_audio_track.dart';
import '../models/mpv_subtitle_track.dart';
import '../models/mpv_tracks.dart';
import '../models/mpv_track_selection.dart';
import '../models/mpv_log.dart';
import 'mpv_player.dart';
import 'mpv_player_state.dart';
import 'mpv_player_streams.dart';

/// Stub implementation of [MpvPlayer].
///
/// This implementation creates all the necessary stream controllers and
/// state management, but throws [UnimplementedError] for all playback
/// methods. It serves as a foundation for platform-specific implementations.
class MpvPlayerStub implements MpvPlayer {
  MpvPlayerState _state = const MpvPlayerState();

  @override
  MpvPlayerState get state => _state;

  late final MpvPlayerStreams _streams;

  @override
  MpvPlayerStreams get streams => _streams;

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
  final _tracksController = StreamController<MpvTracks>.broadcast();
  final _trackController = StreamController<MpvTrackSelection>.broadcast();
  final _logController = StreamController<MpvLog>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _audioDeviceController = StreamController<MpvAudioDevice>.broadcast();
  final _audioDevicesController =
      StreamController<List<MpvAudioDevice>>.broadcast();

  bool _disposed = false;

  MpvPlayerStub() {
    _streams = MpvPlayerStreams(
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
      throw StateError('MpvPlayer has been disposed');
    }
  }

  // ============================================
  // Playback Control
  // ============================================

  @override
  Future<void> open(MpvMedia media, {bool play = true}) async {
    _checkDisposed();
    throw UnimplementedError('MpvPlayer.open() is not yet implemented');
  }

  @override
  Future<void> play() async {
    _checkDisposed();
    throw UnimplementedError('MpvPlayer.play() is not yet implemented');
  }

  @override
  Future<void> pause() async {
    _checkDisposed();
    throw UnimplementedError('MpvPlayer.pause() is not yet implemented');
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
    throw UnimplementedError('MpvPlayer.stop() is not yet implemented');
  }

  @override
  Future<void> seek(Duration position) async {
    _checkDisposed();
    throw UnimplementedError('MpvPlayer.seek() is not yet implemented');
  }

  // ============================================
  // Track Selection
  // ============================================

  @override
  Future<void> selectAudioTrack(MpvAudioTrack track) async {
    _checkDisposed();
    throw UnimplementedError(
        'MpvPlayer.selectAudioTrack() is not yet implemented');
  }

  @override
  Future<void> selectSubtitleTrack(MpvSubtitleTrack track) async {
    _checkDisposed();
    throw UnimplementedError(
        'MpvPlayer.selectSubtitleTrack() is not yet implemented');
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
        'MpvPlayer.addSubtitleTrack() is not yet implemented');
  }

  // ============================================
  // Volume and Rate
  // ============================================

  @override
  Future<void> setVolume(double volume) async {
    _checkDisposed();
    throw UnimplementedError('MpvPlayer.setVolume() is not yet implemented');
  }

  @override
  Future<void> setRate(double rate) async {
    _checkDisposed();
    throw UnimplementedError('MpvPlayer.setRate() is not yet implemented');
  }

  @override
  Future<void> setAudioDevice(MpvAudioDevice device) async {
    _checkDisposed();
    throw UnimplementedError(
        'MpvPlayer.setAudioDevice() is not yet implemented');
  }

  // ============================================
  // MPV Properties
  // ============================================

  @override
  Future<void> setProperty(String name, String value) async {
    _checkDisposed();
    throw UnimplementedError('MpvPlayer.setProperty() is not yet implemented');
  }

  @override
  Future<String?> getProperty(String name) async {
    _checkDisposed();
    throw UnimplementedError('MpvPlayer.getProperty() is not yet implemented');
  }

  @override
  Future<void> command(List<String> args) async {
    _checkDisposed();
    throw UnimplementedError('MpvPlayer.command() is not yet implemented');
  }

  // ============================================
  // Passthrough
  // ============================================

  @override
  Future<void> setAudioPassthrough(bool enabled) async {
    _checkDisposed();
    throw UnimplementedError(
        'MpvPlayer.setAudioPassthrough() is not yet implemented');
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
