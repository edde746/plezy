import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player_drm/video_player.dart' as webos_media;

import '../../../models/audio_channel_limit.dart';
import '../../models.dart';
import '../audio_rendering_mode.dart';
import '../player_base.dart';
import 'webos_media_proxy.dart';

/// LG's native webOS media pipeline, exposed through the official Flutter
/// video-player plugin. webOS reports itself as Linux through `dart:io`, so it
/// must be selected before the generic Linux MPV backend.
class PlayerWebOS extends PlayerBase {
  PlayerWebOS({this.audioOnly = false}) : super(listenToNativeEvents: false);

  static const _methodChannel = MethodChannel('com.plezy/webos_media');
  static const _eventChannel = EventChannel('com.plezy/webos_media/events');
  static int _nextSourceId = 0;

  @override
  MethodChannel get methodChannel => _methodChannel;

  @override
  EventChannel get eventChannel => _eventChannel;

  @override
  String get logPrefix => 'webOS media';

  @override
  String get playerType => 'webos';

  @override
  bool get supportsSecondarySubtitles => false;

  @override
  bool get needsDecoderRefreshAfterDisplaySwitch => false;

  final bool audioOnly;
  final ValueNotifier<int> surfaceRevision = ValueNotifier(0);
  webos_media.VideoPlayerController? _controller;
  WebOSMediaProxy? _proxy;
  int? _sourceId;
  int _generation = 0;
  bool _loaded = false;
  bool _firstFrameSent = false;
  bool _errorSent = false;
  bool _completionQueued = false;
  Media? _nextMedia;
  String? _subtitleSelection;

  bool get hasVideoSurface => !audioOnly && _controller != null;

  Widget videoSurface() {
    final controller = _controller;
    if (audioOnly || controller == null) return const SizedBox.expand();
    return webos_media.VideoPlayer(controller);
  }

  @override
  Future<void> open(
    Media media, {
    bool play = true,
    bool isLive = false,
    List<SubtitleTrack>? externalSubtitles,
    Duration? timelineDuration,
    Duration timelineOffset = Duration.zero,
  }) async {
    if (disposed) return;
    final generation = ++_generation;
    await _releaseSource();
    if (disposed || generation != _generation) return;

    final startPosition = media.start ?? timelineOffset;
    configureTimeline(duration: timelineDuration, offset: timelineOffset);
    clearTracks();
    setExternalSubtitleMetadata(externalSubtitles);
    resetPlaybackProgress(startPosition);
    setSeekable(false);

    final sourceId = ++_nextSourceId;
    _sourceId = sourceId;
    _loaded = false;
    _firstFrameSent = false;
    _errorSent = false;
    _completionQueued = false;
    handlePlayerEvent('start-file', {'sourceId': sourceId});

    webos_media.VideoPlayerController? controller;
    WebOSMediaProxy? proxy;
    try {
      final sourceUri = Uri.parse(media.uri);
      Uri playerUri;
      if (sourceUri.scheme == 'http' || sourceUri.scheme == 'https') {
        proxy = await WebOSMediaProxy.bind();
        if (disposed || generation != _generation) {
          await proxy.close();
          return;
        }
        playerUri = proxy.register(sourceUri, headers: media.headers);
      } else if (sourceUri.scheme == 'file') {
        playerUri = sourceUri;
      } else if (sourceUri.scheme.isEmpty && media.uri.startsWith('/')) {
        playerUri = Uri.file(media.uri);
      } else {
        throw const FormatException('webOS playback requires an HTTP(S) stream or an app-local file');
      }

      controller = playerUri.scheme == 'file'
          ? webos_media.VideoPlayerController.file(File.fromUri(playerUri))
          : webos_media.VideoPlayerController.network(playerUri, httpHeaders: const {});
      _controller = controller;
      _proxy = proxy;
      controller.addListener(() => _onControllerValue(controller!, sourceId, generation, isLive: isLive));
      surfaceRevision.value++;

      await controller.initialize();
      if (disposed || generation != _generation) return;
      _adoptControllerValue(controller, sourceId, generation, isLive: isLive);

      final sourceStart = sourcePositionFor(startPosition);
      if (sourceStart > Duration.zero) await controller.seekTo(sourceStart);
      if (play) await controller.play();
      if (disposed || generation != _generation) return;
    } catch (error) {
      if (generation == _generation && !disposed) {
        _emitFailure(sourceId);
        await _releaseSource();
      } else {
        await controller?.dispose();
        await proxy?.close();
      }
      rethrow;
    }
  }

  void _onControllerValue(
    webos_media.VideoPlayerController controller,
    int sourceId,
    int generation, {
    required bool isLive,
  }) {
    if (disposed || generation != _generation || !identical(controller, _controller)) return;
    if (controller.value.errorDescription != null) {
      _emitFailure(sourceId);
      return;
    }
    _adoptControllerValue(controller, sourceId, generation, isLive: isLive);
  }

  void _adoptControllerValue(
    webos_media.VideoPlayerController controller,
    int sourceId,
    int generation, {
    required bool isLive,
  }) {
    if (generation != _generation || disposed) return;
    final value = controller.value;
    if (value.isInitialized && !_loaded) {
      _loaded = true;
      handlePlayerEvent('file-loaded', {'sourceId': sourceId});
      _adoptTracks(value);
      primaryMediaReadyController.add(null);
      setSeekable(!isLive && value.duration > Duration.zero);
    }

    if (!value.isInitialized) return;
    handlePropertyChange('duration', value.duration.inMilliseconds / Duration.millisecondsPerSecond);
    handlePropertyChange('pause', !value.isPlaying);
    handlePropertyChange('paused-for-cache', value.isBuffering);
    handlePropertyChange('time-pos', value.position.inMilliseconds / Duration.millisecondsPerSecond);
    if (value.buffered.isNotEmpty) {
      final end = value.buffered.map((range) => range.end).reduce((a, b) => a > b ? a : b);
      handlePropertyChange('demuxer-cache-time', end.inMilliseconds / Duration.millisecondsPerSecond);
    }

    if (!_firstFrameSent && value.isPlaying && value.position > Duration.zero) {
      _firstFrameSent = true;
      handlePlayerEvent('playback-restart', {
        'sourceId': sourceId,
        'positionSeconds': value.position.inMilliseconds / Duration.millisecondsPerSecond,
      });
    }

    if (value.isCompleted && !_completionQueued) {
      _completionQueued = true;
      final next = audioOnly ? _nextMedia : null;
      _nextMedia = null;
      if (next != null) {
        unawaited(_advanceAudio(next, sourceId));
      } else {
        handlePropertyChange('eof-reached', true);
      }
    }

    _adoptTracks(value);
  }

  void _adoptTracks(webos_media.VideoPlayerValue value) {
    final audioRows = value.audioTracks ?? const <Map<String, dynamic>>[];
    final subtitleRows = value.subtitleTracks ?? const <Map<String, dynamic>>[];
    final audio = <AudioTrack>[
      for (var index = 0; index < audioRows.length; index++)
        AudioTrack(
          id: '$index',
          title: _trackLabel(audioRows[index], index),
          language: _stringField(audioRows[index], 'language'),
        ),
    ];
    final subtitles = <SubtitleTrack>[
      SubtitleTrack.off,
      for (var index = 0; index < subtitleRows.length; index++)
        SubtitleTrack(
          id: '$index',
          title: _trackLabel(subtitleRows[index], index),
          language: _stringField(subtitleRows[index], 'language'),
          isContainer: true,
        ),
    ];
    updateTracks(Tracks(audio: audio, subtitle: subtitles));
    final currentAudio = value.currentAudioTrack;
    if (currentAudio != null && currentAudio >= 0 && currentAudio < audio.length) {
      updateSelectedAudioTrack('$currentAudio');
    }
    final subtitleSelection = _subtitleSelection;
    if (subtitleSelection != null) updateSelectedSubtitleTrack(subtitleSelection);
  }

  String _trackLabel(Map<String, dynamic> row, int index) {
    final language = _stringField(row, 'language');
    return language == null || language.isEmpty ? 'Track ${index + 1}' : language;
  }

  String? _stringField(Map<String, dynamic> row, String field) {
    final value = row[field];
    return value is String && value.trim().isNotEmpty ? value.trim() : null;
  }

  void _emitFailure(int sourceId) {
    if (_errorSent || disposed) return;
    _errorSent = true;
    handlePlayerEvent('end-file', {
      'sourceId': sourceId,
      'reason': 'error',
      // Native error text can include a media URI. Never surface it to logs.
      'message': 'The webOS media player could not load this stream.',
    });
  }

  Future<void> _advanceAudio(Media next, int previousSourceId) async {
    try {
      await open(next, play: true);
      if (!disposed) trackTransitionController.add(next.uri);
    } catch (_) {
      if (!disposed) {
        handlePlayerEvent('end-file', {
          'sourceId': previousSourceId,
          'reason': 'error',
          'message': 'The next audio track could not be started.',
        });
      }
    }
  }

  Future<void> _releaseSource() async {
    final controller = _controller;
    _controller = null;
    await _proxy?.close();
    _proxy = null;
    if (controller != null) {
      try {
        await controller.dispose();
      } on PlatformException {
        // Disposal is best effort after a native pipeline error.
      } on MissingPluginException {
        // The native pipeline may already have released this controller.
      }
    }
    surfaceRevision.value++;
  }

  @override
  Future<void> play() async {
    final controller = _controller;
    if (disposed || controller == null) return;
    await controller.play();
    handlePropertyChange('pause', false);
  }

  @override
  Future<void> pause() async {
    final controller = _controller;
    if (disposed || controller == null) return;
    await controller.pause();
    handlePropertyChange('pause', true);
  }

  @override
  Future<void> stop() async {
    if (disposed) return;
    final sourceId = _sourceId;
    await _releaseSource();
    if (sourceId != null) handlePlayerEvent('end-file', {'sourceId': sourceId, 'reason': 'stop'});
    resetPlaybackProgress(Duration.zero);
    setSeekable(false);
    clearTracks();
  }

  @override
  Future<void> seek(Duration position) async {
    final controller = _controller;
    if (disposed || controller == null || !controller.value.isInitialized) return;
    final target = position < Duration.zero ? Duration.zero : position;
    await runSeek(target, () async => controller.seekTo(sourcePositionFor(target)));
  }

  @override
  Future<void> selectAudioTrack(AudioTrack track) async {
    final controller = _controller;
    final index = int.tryParse(track.id);
    if (disposed || controller == null || index == null || index < 0) return;
    await controller.selectAudioTrack(index);
    updateSelectedAudioTrack(track.id);
  }

  @override
  Future<void> selectSubtitleTrack(SubtitleTrack track) async {
    final controller = _controller;
    if (disposed || controller == null) return;
    if (track.id == SubtitleTrack.off.id || track.id == 'auto') {
      await controller.setSubtitleEnabled(false);
      _subtitleSelection = SubtitleTrack.off.id;
      updateSelectedSubtitleTrack(SubtitleTrack.off.id);
      return;
    }
    final index = int.tryParse(track.id);
    if (index == null || index < 0) return;
    await controller.selectSubtitleTrack(index);
    await controller.setSubtitleEnabled(true);
    _subtitleSelection = track.id;
    updateSelectedSubtitleTrack(track.id);
  }

  @override
  Future<void> setVolume(double volume) async {
    final clamped = volume.clamp(0, 100).toDouble();
    final controller = _controller;
    if (controller != null) {
      try {
        await controller.setVolume(clamped / 100);
      } on PlatformException catch (error) {
        if (error.code != 'unsupported') rethrow;
      }
    }
    // webOS TV exposes system volume through the remote; the LG media plugin
    // cannot apply per-stream gain. Keep the player's mirror in range without
    // making playback depend on an unsupported native operation.
    setVolumeState(100);
  }

  @override
  Future<void> setRate(double rate) async {
    final controller = _controller;
    if (disposed || controller == null) return;
    await controller.setPlaybackSpeed(rate);
    setRateState(rate);
  }

  @override
  Future<void> setAudioDevice(AudioDevice device) async {}

  @override
  Future<void> setProperty(String name, String value) async {
    if (disposed) return;
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
        await setRate(double.tryParse(value) ?? 1);
        break;
      case 'sub-visibility':
        final controller = _controller;
        if (controller != null) await controller.setSubtitleEnabled(value == 'yes');
        break;
      case 'sub-delay':
        final controller = _controller;
        final milliseconds = ((double.tryParse(value) ?? 0) * 1000).round();
        if (controller != null) await controller.setSubtitleSync(milliseconds);
        break;
      default:
        // MPV-only tuning properties have no LG media equivalent.
        break;
    }
  }

  @override
  Future<String?> getProperty(String name) async {
    final controller = _controller;
    final value = controller?.value;
    return switch (name) {
      'pause' => state.playing ? 'no' : 'yes',
      'volume' => state.volume.toString(),
      'speed' => state.rate.toString(),
      'time-pos' => ((value?.position.inMilliseconds ?? 0) / Duration.millisecondsPerSecond).toString(),
      'duration' => ((value?.duration.inMilliseconds ?? 0) / Duration.millisecondsPerSecond).toString(),
      'seekable' => state.seekable ? 'yes' : 'no',
      'width' || 'dwidth' => value?.size.width.toInt().toString(),
      'height' || 'dheight' => value?.size.height.toInt().toString(),
      _ => null,
    };
  }

  @override
  Future<void> setLogLevel(String level) async {}

  @override
  Future<void> command(List<String> args) async {}

  @override
  Future<void> configureSubtitleFonts() async {}

  @override
  Future<void> setAudioPassthrough(bool enabled) async {}

  @override
  Future<AudioRenderingMode?> getAudioRenderingMode() async => null;

  @override
  Future<void> setAudioNormalization(bool enabled) async {}

  @override
  Future<void> setAudioChannelLimit(
    AudioChannelLimit limit, {
    required int centerBoostDb,
    required bool normalize,
  }) async {}

  @override
  Future<bool> setVisible(bool visible, {bool restoreOnWindowVisible = false}) async => true;

  @override
  Future<bool> requestAudioFocus() async => true;

  @override
  Future<void> abandonAudioFocus() async {}

  @override
  Future<void> setNext(Media? media) async {
    if (audioOnly && !disposed) _nextMedia = media;
  }

  @override
  Future<void> selectSecondarySubtitleTrack(SubtitleTrack track) async {}

  @override
  Future<void> dispose({bool preserveDisplayMode = false}) async {
    if (disposed) return;
    _generation++;
    await _releaseSource();
    surfaceRevision.dispose();
    await super.dispose(preserveDisplayMode: preserveDisplayMode);
  }
}
