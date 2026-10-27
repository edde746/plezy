import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player_videohole/video_player.dart' as samsung;

import '../../../models/audio_channel_limit.dart';
import '../../../utils/serial_future_queue.dart';
import '../../models.dart';
import '../audio_rendering_mode.dart';
import '../player_base.dart';
import 'webos_media_proxy.dart';

/// Samsung's native media plane. The existing app supplies browsing, focus,
/// transport controls and watch progress; no browser-hosted UI is involved.
class PlayerTizen extends PlayerBase {
  PlayerTizen({this.audioOnly = false}) : super(listenToNativeEvents: false);

  final bool audioOnly;
  final ValueNotifier<int> surfaceRevision = ValueNotifier(0);
  final ValueNotifier<String> caption = ValueNotifier('');
  final SerialFutureQueue _sources = SerialFutureQueue();
  samsung.VideoPlayerController? _controller;
  WebOSMediaProxy? _proxy;
  Media? _media;
  Media? _nextMedia;
  List<SubtitleTrack> _externalSubtitles = const [];
  samsung.ClosedCaptionFile? _captions;
  int _generation = 0;
  int _subtitleGeneration = 0;
  int? _sourceId;
  static int _nextSourceId = 0;
  bool _closing = false;
  bool _loaded = false;
  bool _firstFrame = false;
  Duration _lastObservedPosition = Duration.zero;
  bool _failed = false;
  bool _completed = false;
  bool _subtitlesVisible = false;
  Duration _subtitleDelay = Duration.zero;

  @override
  MethodChannel get methodChannel => const MethodChannel('com.plezy/tizen_media');
  @override
  EventChannel get eventChannel => const EventChannel('com.plezy/tizen_media/events');
  @override
  String get logPrefix => 'Tizen media';
  @override
  String get playerType => 'tizen';
  @override
  bool get supportsSecondarySubtitles => false;
  @override
  bool get needsDecoderRefreshAfterDisplaySwitch => false;

  bool _current(int generation) => !disposed && !_closing && generation == _generation;

  Widget videoSurface() {
    final controller = _controller;
    if (audioOnly || controller == null) return const SizedBox.expand();
    return Stack(
      fit: StackFit.expand,
      children: [
        samsung.VideoPlayer(controller),
        IgnorePointer(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 16, 32, 36),
              child: ValueListenableBuilder<String>(
                valueListenable: caption,
                builder: (context, text, child) =>
                    text.isEmpty ? const SizedBox.shrink() : samsung.ClosedCaption(text: text),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Future<void> open(
    Media media, {
    bool play = true,
    bool isLive = false,
    List<SubtitleTrack>? externalSubtitles,
    Duration? timelineDuration,
    Duration timelineOffset = Duration.zero,
  }) {
    if (disposed || _closing) return Future.value();
    final generation = ++_generation;
    _nextMedia = null;
    return _sources.run(() async {
      if (!_current(generation)) return;
      await _releaseSource();
      if (!_current(generation)) return;
      _media = media;
      _externalSubtitles = externalSubtitles ?? const [];
      final start = media.start ?? timelineOffset;
      configureTimeline(duration: timelineDuration, offset: timelineOffset);
      clearTracks();
      setExternalSubtitleMetadata(externalSubtitles);
      resetPlaybackProgress(start);
      setSeekable(false);
      final sourceId = ++_nextSourceId;
      _sourceId = sourceId;
      _loaded = _firstFrame = _failed = _completed = false;
      _lastObservedPosition = Duration.zero;
      handlePlayerEvent('start-file', {'sourceId': sourceId});
      try {
        final uri = Uri.parse(media.uri);
        late final samsung.VideoPlayerController controller;
        if (uri.scheme == 'http' || uri.scheme == 'https') {
          final proxy = await WebOSMediaProxy.bind();
          _proxy = proxy;
          // Samsung only forwards Cookie/User-Agent. The loopback bridge
          // forwards authenticated byte ranges and same-origin HLS children.
          final local = proxy.register(uri, headers: media.headers);
          controller = samsung.VideoPlayerController.network(local.toString());
        } else if (uri.scheme == 'file' || (uri.scheme.isEmpty && media.uri.startsWith('/'))) {
          controller = samsung.VideoPlayerController.file(uri.scheme == 'file' ? File.fromUri(uri) : File(media.uri));
        } else {
          throw const FormatException('Tizen playback requires HTTP(S) or an app-local file');
        }
        _controller = controller;
        controller.addListener(() => _onValue(controller, generation, sourceId, isLive));
        surfaceRevision.value++;
        await controller.initialize().timeout(const Duration(seconds: 45));
        if (!_current(generation)) return;
        await _loadTracks(controller, generation);
        if (!_current(generation)) return;
        if (sourcePositionFor(start) > Duration.zero) await controller.seekTo(sourcePositionFor(start));
        if (!_current(generation)) return;
        await controller.setVolume(state.volume / 100);
        await controller.setPlaybackSpeed(state.rate);
        if (_current(generation) && play) await controller.play();
      } catch (_) {
        if (_current(generation)) _fail(sourceId);
        await _releaseSource();
        // Native errors can contain credentials, paths or stream URLs.
        throw PlatformException(code: 'tizen-playback', message: 'Samsung TV could not open this media.');
      } finally {
        if (!_current(generation)) await _releaseSource();
      }
    });
  }

  void _onValue(samsung.VideoPlayerController controller, int generation, int sourceId, bool live) {
    if (!_current(generation) || !identical(controller, _controller)) return;
    final value = controller.value;
    if (value.hasError) {
      _fail(sourceId);
      return;
    }
    if (!value.isInitialized) return;
    if (!_loaded) {
      _loaded = true;
      handlePlayerEvent('file-loaded', {'sourceId': sourceId});
      primaryMediaReadyController.add(null);
    }
    setSeekable(!live && value.duration.end > Duration.zero);
    handlePropertyChange('duration', value.duration.end.inMilliseconds / 1000);
    handlePropertyChange('pause', !value.isPlaying);
    handlePropertyChange('paused-for-cache', value.isBuffering);
    handlePropertyChange('time-pos', value.position.inMilliseconds / 1000);
    _updateCaption();
    // initialize/seek/play update ValueNotifier optimistically. Only a later
    // advancing playback clock is evidence for the app's first-frame gate.
    if (!_firstFrame && value.isPlaying && value.position > _lastObservedPosition) {
      _firstFrame = true;
      handlePlayerEvent('playback-restart', {'sourceId': sourceId});
    }
    _lastObservedPosition = value.position;
    if (!live && value.isCompleted && !_completed) {
      _completed = true;
      final next = audioOnly ? _nextMedia : null;
      _nextMedia = null;
      if (next == null) {
        handlePropertyChange('eof-reached', true);
      } else {
        unawaited(_advance(next, generation));
      }
    }
  }

  Future<void> _advance(Media media, int generation) async {
    if (!_current(generation)) return;
    try {
      takeSourceOwnership();
      await open(media);
      if (!disposed && !_closing && generation + 1 == _generation) trackTransitionController.add(media.uri);
    } catch (_) {
      // open emitted the sanitized source failure.
    }
  }

  Future<void> _loadTracks(samsung.VideoPlayerController controller, int generation) async {
    final audio = await controller.audioTracks ?? [];
    final text = await controller.textTracks ?? [];
    if (!_current(generation)) return;
    updateTracks(
      Tracks(
        audio: [for (final track in audio) AudioTrack(id: '${track.trackId}', language: track.language)],
        subtitle: [
          SubtitleTrack.off,
          for (final track in text) SubtitleTrack(id: '${track.trackId}', language: track.language, isContainer: true),
          ..._externalSubtitles,
        ],
      ),
    );
    // value.tracks contains the native selection, not the available tracks.
    for (final track in controller.value.tracks.whereType<samsung.AudioTrack>()) {
      updateSelectedAudioTrack('${track.trackId}');
    }
    updateSelectedSubtitleTrack(SubtitleTrack.off.id);
  }

  void _fail(int sourceId) {
    if (_failed || disposed || _closing) return;
    _failed = true;
    handlePlayerEvent('end-file', {
      'sourceId': sourceId,
      'reason': 'error',
      'message': 'Samsung TV could not play this media. Try server transcoding.',
    });
  }

  Future<void> _releaseSource() async {
    final controller = _controller;
    final proxy = _proxy;
    _controller = null;
    _proxy = null;
    _subtitleGeneration++;
    _captions = null;
    _subtitlesVisible = false;
    caption.value = '';
    surfaceRevision.value++;
    try {
      await controller?.dispose();
    } finally {
      await proxy?.close();
    }
  }

  @override
  Future<void> play() async {
    if (disposed || _closing) return;
    await _controller?.play();
  }

  @override
  Future<void> pause() async {
    if (disposed || _closing) return;
    await _controller?.pause();
  }

  @override
  Future<void> stop() {
    if (disposed || _closing) return Future.value();
    ++_generation;
    _nextMedia = null;
    return _sources.run(() async {
      await _releaseSource();
      final id = _sourceId;
      _sourceId = null;
      if (id != null) handlePlayerEvent('end-file', {'sourceId': id, 'reason': 'stop'});
      resetPlaybackProgress(Duration.zero);
      handlePropertyChange('pause', true);
      handlePropertyChange('paused-for-cache', false);
      setSeekable(false);
      clearTracks();
    });
  }

  @override
  Future<void> seek(Duration position) async {
    final controller = _controller;
    if (disposed || _closing || controller == null || !controller.value.isInitialized) return;
    final generation = _generation;
    final rate = controller.value.playbackSpeed;
    final target = sourcePositionFor(position < Duration.zero ? Duration.zero : position);
    // Samsung rejects seeks at non-unit playback speed.
    await runSeek(position, () async {
      if (rate != 1) await controller.setPlaybackSpeed(1);
      try {
        if (_current(generation)) await controller.seekTo(target);
      } finally {
        if (_current(generation) && rate != 1) await controller.setPlaybackSpeed(rate);
      }
    });
  }

  @override
  Future<void> selectAudioTrack(AudioTrack track) async {
    final controller = _controller;
    final id = int.tryParse(track.id);
    if (disposed || _closing || controller == null || id == null) return;
    final generation = _generation;
    if (!await controller.setTrackSelection(samsung.Track(trackId: id, trackType: samsung.TrackType.audio))) {
      throw PlatformException(code: 'tizen-audio-track', message: 'This audio track could not be selected.');
    }
    if (_current(generation)) updateSelectedAudioTrack(track.id);
  }

  @override
  Future<void> selectSubtitleTrack(SubtitleTrack track) async {
    final controller = _controller;
    if (disposed || _closing || controller == null) return;
    final generation = _generation;
    final selection = ++_subtitleGeneration;
    if (track.id == SubtitleTrack.off.id || track.id == 'auto') {
      _captions = null;
      _subtitlesVisible = false;
    } else if (track.uri != null) {
      final parsed = await _readCaptions(track);
      if (!_current(generation) || selection != _subtitleGeneration) return;
      _captions = parsed;
      _subtitlesVisible = true;
    } else {
      final id = int.tryParse(track.id);
      if (id == null) return;
      final accepted = await controller.setTrackSelection(
        samsung.Track(trackId: id, trackType: samsung.TrackType.text),
      );
      if (!_current(generation) || selection != _subtitleGeneration) return;
      if (!accepted) {
        throw PlatformException(code: 'tizen-subtitle-track', message: 'This subtitle track could not be selected.');
      }
      _captions = null;
      _subtitlesVisible = true;
    }
    _updateCaption();
    updateSelectedSubtitleTrack(_subtitlesVisible ? track.id : SubtitleTrack.off.id);
  }

  Future<samsung.ClosedCaptionFile> _readCaptions(SubtitleTrack track) async {
    final uri = Uri.parse(track.uri!);
    final source = Uri.tryParse(_media?.uri ?? '');
    final codec = track.codec?.toLowerCase();
    final isVtt = codec == 'vtt' || uri.path.toLowerCase().endsWith('.vtt');
    if (!isVtt && codec != 'srt' && codec != 'subrip' && !uri.path.toLowerCase().endsWith('.srt')) {
      throw UnsupportedError('Samsung TV supports SRT/VTT sidecars; use server subtitle burn-in for this format.');
    }
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      if (uri.scheme != 'http' && uri.scheme != 'https') throw const FormatException('Subtitle URL requires HTTP(S)');
      final proxy = _proxy;
      if (proxy == null) throw StateError('No authenticated subtitle transport');
      final local = proxy.register(uri, headers: source?.origin == uri.origin ? _media?.headers : null);
      final response = await (await client.getUrl(local)).close().timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) throw const HttpException('Subtitle download failed');
      final bytes = <int>[];
      await for (final chunk in response.timeout(const Duration(seconds: 15))) {
        if (bytes.length + chunk.length > 2 * 1024 * 1024) throw const FormatException('Subtitle file exceeds 2 MiB');
        bytes.addAll(chunk);
      }
      final content = utf8.decode(bytes);
      return isVtt ? samsung.WebVTTCaptionFile(content) : samsung.SubRipCaptionFile(content);
    } finally {
      client.close(force: true);
    }
  }

  void _updateCaption() {
    final value = _controller?.value;
    var text = '';
    if (_subtitlesVisible && value != null) {
      final position = value.position - _subtitleDelay;
      final cues = _captions?.captions ?? [value.caption];
      for (final cue in cues) {
        if (position >= cue.start && position < cue.end) {
          text = cue.text;
          break;
        }
      }
    }
    if (caption.value != text) caption.value = text;
  }

  @override
  Future<void> setVolume(double volume) async {
    if (disposed || _closing) return;
    final clamped = volume.clamp(0, 100).toDouble();
    await _controller?.setVolume(clamped / 100);
    setVolumeState(clamped);
  }

  @override
  Future<void> setRate(double rate) async {
    if (!rate.isFinite || rate <= 0) throw ArgumentError.value(rate, 'rate');
    if (disposed || _closing) return;
    await _controller?.setPlaybackSpeed(rate);
    setRateState(rate);
  }

  @override
  Future<void> setProperty(String name, String value) async {
    if (disposed || _closing) return;
    switch (name) {
      case 'pause':
        await (value == 'yes' ? pause() : play());
      case 'volume':
        await setVolume(double.tryParse(value) ?? 100);
      case 'speed':
        await setRate(double.tryParse(value) ?? 1);
      case 'sub-visibility':
        _subtitlesVisible =
            value == 'yes' && state.track.subtitle != null && state.track.subtitle?.id != SubtitleTrack.off.id;
        _updateCaption();
      case 'sub-delay':
        _subtitleDelay = Duration(milliseconds: ((double.tryParse(value) ?? 0) * 1000).round());
        _updateCaption();
    }
  }

  @override
  Future<String?> getProperty(String name) async => switch (name) {
    'pause' => state.playing ? 'no' : 'yes',
    'volume' => state.volume.toString(),
    'speed' => state.rate.toString(),
    'time-pos' => ((_controller?.value.position.inMilliseconds ?? 0) / 1000).toString(),
    'duration' => ((_controller?.value.duration.end.inMilliseconds ?? 0) / 1000).toString(),
    'seekable' => state.seekable ? 'yes' : 'no',
    'width' || 'dwidth' => _controller?.value.size.width.toInt().toString(),
    'height' || 'dheight' => _controller?.value.size.height.toInt().toString(),
    _ => null,
  };

  // Samsung owns the display/audio route. MPV tuning has no native equivalent.
  @override
  Future<void> setAudioDevice(AudioDevice device) async {}
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
  Future<bool> setVisible(bool visible, {bool restoreOnWindowVisible = false}) async {
    if (!visible) await pause();
    return !disposed && !_closing;
  }

  @override
  Future<bool> requestAudioFocus() async => !disposed && !_closing;
  @override
  Future<void> abandonAudioFocus() async {}
  @override
  Future<void> setNext(Media? media) async {
    if (audioOnly && !disposed && !_closing) _nextMedia = media;
  }

  @override
  Future<void> selectSecondarySubtitleTrack(SubtitleTrack track) async {}

  Future<void>? _disposeFuture;
  @override
  Future<void> dispose({bool preserveDisplayMode = false}) => _disposeFuture ??= _dispose(preserveDisplayMode);

  Future<void> _dispose(bool preserveDisplayMode) async {
    _closing = true;
    ++_generation;
    _nextMedia = null;
    try {
      await _sources.run(_releaseSource);
    } finally {
      surfaceRevision.dispose();
      caption.dispose();
      await super.dispose(preserveDisplayMode: preserveDisplayMode);
    }
  }
}
