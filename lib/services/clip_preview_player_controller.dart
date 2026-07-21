import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../i18n/strings.g.dart';
import '../mpv/models.dart';
import '../mpv/player/player.dart';
import '../mpv/player/video_rect_support.dart';
import 'clip_export_service.dart';

class ClipPreviewPlayerState {
  final Duration position;
  final bool playing;
  final bool firstFrame;
  final double volume;
  final bool screenshotting;
  final String? error;

  const ClipPreviewPlayerState({
    this.position = Duration.zero,
    this.playing = false,
    this.firstFrame = false,
    this.volume = 0,
    this.screenshotting = false,
    this.error,
  });

  ClipPreviewPlayerState copyWith({
    Duration? position,
    bool? playing,
    bool? firstFrame,
    double? volume,
    bool? screenshotting,
    String? error,
  }) {
    return ClipPreviewPlayerState(
      position: position ?? this.position,
      playing: playing ?? this.playing,
      firstFrame: firstFrame ?? this.firstFrame,
      volume: volume ?? this.volume,
      screenshotting: screenshotting ?? this.screenshotting,
      error: error,
    );
  }
}

abstract class ClipPreviewPlayerBackend {
  Player? get player;
  Stream<Duration> get positions;
  Stream<bool> get playing;
  Stream<void> get firstFrames;

  Future<void> open({required ClipSource source, required Duration sourceStart, required double maxVolume});

  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration videoPosition);
  Future<void> setVolume(double volume);
  Future<void> captureScreenshot(String outputPath);
  Future<void> hideSurfaceNow();
  Future<void> releasePlayer();
  Future<void> dispose();
}

class PlayerClipPreviewPlayerBackend implements ClipPreviewPlayerBackend {
  final Player Function() _playerFactory;
  final _positions = StreamController<Duration>.broadcast();
  final _playing = StreamController<bool>.broadcast();
  final _firstFrames = StreamController<void>.broadcast();
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  Player? _player;

  PlayerClipPreviewPlayerBackend({Player Function()? playerFactory})
    : _playerFactory = playerFactory ?? Player.preview {
    // Build the Dart player before the sheet's first frame so its Video widget
    // is listening before a fast paused load reports its first frame.
    _ensurePlayer();
  }

  @override
  Player? get player => _player;

  @override
  Stream<Duration> get positions => _positions.stream;

  @override
  Stream<bool> get playing => _playing.stream;

  @override
  Stream<void> get firstFrames => _firstFrames.stream;

  Player _ensurePlayer() {
    final existing = _player;
    if (existing != null) return existing;

    final player = _playerFactory();
    _player = player;
    _subscriptions.add(player.streams.position.listen(_positions.add));
    _subscriptions.add(player.streams.playing.listen(_playing.add));
    // A paused load can produce a drawable frame without emitting
    // playback-restart. Treat file-loaded as the readiness fallback so the
    // poster does not permanently cover the native preview surface.
    _subscriptions.add(player.streams.fileLoaded.listen(_firstFrames.add));
    _subscriptions.add(player.streams.playbackRestart.listen(_firstFrames.add));
    return player;
  }

  @override
  Future<void> open({required ClipSource source, required Duration sourceStart, required double maxVolume}) async {
    final player = _ensurePlayer();
    await player.setProperty('cache', 'yes');
    await player.setProperty('cache-on-disk', 'yes');
    await player.setProperty('cache-secs', '300');
    await player.setProperty('demuxer-max-bytes', '268435456');
    await player.setProperty('demuxer-max-back-bytes', '268435456');
    await player.setProperty('sid', 'no');
    await player.setProperty('secondary-sid', 'no');
    await player.setProperty('volume-max', maxVolume.toString());
    final subtitle = source.subtitleTrack;
    await player.open(
      Media(source.uri, headers: source.headers, start: sourceStart),
      play: false,
      externalSubtitles: subtitle?.uri == null ? null : [subtitle!],
      timelineOffset: source.isTranscoding ? source.timelineOffset : Duration.zero,
      timelineDuration: source.duration,
    );
    if (source.audioTrack != null) await player.selectAudioTrack(source.audioTrack!);
    if (subtitle != null) await player.selectSubtitleTrack(subtitle.uri == null ? subtitle : SubtitleTrack.auto);
    await player.setProperty('sub-visibility', source.initialSubtitlesEnabled ? 'yes' : 'no');
  }

  @override
  Future<void> play() async {
    await _player?.play();
  }

  @override
  Future<void> pause() async {
    await _player?.pause();
  }

  @override
  Future<void> seek(Duration videoPosition) async {
    await _player?.seek(videoPosition);
  }

  @override
  Future<void> setVolume(double volume) async {
    await _player?.setVolume(volume);
  }

  @override
  Future<void> captureScreenshot(String outputPath) async {
    await _player?.command(buildScreenshotCommand(outputPath));
  }

  @visibleForTesting
  static List<String> buildScreenshotCommand(String outputPath) => ['screenshot-to-file', outputPath, 'video'];

  Future<void> _hideSurface({required bool pause}) async {
    final player = _player;
    if (player == null || player.disposed) return;

    final futures = <Future<void>>[player.setVisible(false).then((_) {})];
    if (pause) futures.add(player.pause());
    if (player is VideoRectSupport) {
      futures.add(player.setVideoRect(left: 0, top: 0, right: 0, bottom: 0, devicePixelRatio: 1));
    }
    try {
      await Future.wait(futures, eagerError: false);
    } catch (_) {
      // Teardown should never keep a native preview surface visible.
    }
  }

  @override
  Future<void> hideSurfaceNow() async {
    await _hideSurface(pause: true);
  }

  @override
  Future<void> releasePlayer() async {
    await hideSurfaceNow();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    final player = _player;
    _player = null;
    await player?.dispose();
  }

  @override
  Future<void> dispose() async {
    await releasePlayer();
    await _positions.close();
    await _playing.close();
    await _firstFrames.close();
  }
}

class ClipPreviewPlayerController extends ValueNotifier<ClipPreviewPlayerState> {
  final ClipPreviewPlayerBackend _backend;
  final double maxVolume;
  final Future<Directory> Function()? screenshotDirectoryProvider;
  late final StreamSubscription<Duration> _positionSubscription;
  late final StreamSubscription<bool> _playingSubscription;
  late final StreamSubscription<void> _firstFrameSubscription;

  ClipSource? _source;
  ClipSelection? _selection;
  bool _opened = false;
  bool _surfaceHideRequested = false;
  late double _lastNonZeroVolume;

  ClipPreviewPlayerController({
    ClipPreviewPlayerBackend? backend,
    double initialVolume = 0,
    double lastNonZeroVolume = 100,
    this.maxVolume = 100,
    this.screenshotDirectoryProvider,
  }) : assert(maxVolume >= 0),
       _backend = backend ?? PlayerClipPreviewPlayerBackend(),
       super(ClipPreviewPlayerState(volume: initialVolume.clamp(0.0, maxVolume).toDouble())) {
    _lastNonZeroVolume = lastNonZeroVolume.clamp(0.0, maxVolume).toDouble();
    if (_lastNonZeroVolume == 0) {
      _lastNonZeroVolume = 100.0.clamp(0.0, maxVolume).toDouble();
    }
    _positionSubscription = _backend.positions.listen(_handleBackendPosition);
    _playingSubscription = _backend.playing.listen((playing) {
      value = value.copyWith(playing: playing, error: value.error);
    });
    _firstFrameSubscription = _backend.firstFrames.listen((_) {
      value = value.copyWith(firstFrame: true, error: value.error);
    });
  }

  Player? get player => _backend.player;
  ClipSelection? get selection => _selection;
  bool get isOpen => _opened;
  bool get hasSubtitles => _source?.hasSubtitleTrack ?? false;

  static ({double initialVolume, double lastNonZeroVolume}) volumeDefaultsForMainPlayer({
    required bool playing,
    required double volume,
    required double savedVolume,
    required double maxVolume,
  }) {
    final safeMax = maxVolume < 0 ? 0.0 : maxVolume;
    final current = volume.clamp(0.0, safeMax).toDouble();
    final saved = savedVolume.clamp(0.0, safeMax).toDouble();
    final restore = current > 0 ? current : (saved > 0 ? saved : 100.0.clamp(0.0, safeMax).toDouble());
    return (initialVolume: playing && current > 0 ? 0 : restore, lastNonZeroVolume: restore);
  }

  Future<void> open(ClipSource source, ClipSelection selection) async {
    final clamped = selection.clampedTo(source.duration);
    _source = source;
    _selection = clamped;
    _opened = false;
    _surfaceHideRequested = false;
    value = ClipPreviewPlayerState(position: clamped.end, volume: value.volume);

    try {
      final sourceStart = ClipExportService.sourceStartForPosition(source, clamped.end);
      await _backend.open(source: source, sourceStart: sourceStart, maxVolume: maxVolume);
      await _backend.setVolume(value.volume);
      _opened = true;
      if (_surfaceHideRequested) {
        unawaited(_backend.hideSurfaceNow());
        return;
      }
      await seekToVideoTime(clamped.end);
    } on MissingPluginException {
      value = value.copyWith(error: t.videoControls.clip.previewUnavailable);
    } on PlatformException catch (e) {
      value = value.copyWith(error: e.message ?? t.videoControls.clip.previewFailed);
    } catch (e) {
      value = value.copyWith(error: e.toString());
    }
  }

  Future<void> setSelection(ClipSelection selection) async {
    final source = _source;
    if (source == null) return;

    final clamped = selection.clampedTo(source.duration);
    _selection = clamped;
    final current = value.position;
    if (current < clamped.start || current > clamped.end) {
      await seekToVideoTime(current < clamped.start ? clamped.start : clamped.end);
    }
  }

  Future<void> play() async {
    final selection = _selection;
    if (!_opened || selection == null) return;
    if (value.position >= selection.end) {
      await seekToVideoTime(selection.start);
    }
    try {
      await _backend.play();
      value = value.copyWith(playing: true, error: value.error);
    } catch (e) {
      value = value.copyWith(playing: false, error: e.toString());
    }
  }

  Future<void> pause() async {
    try {
      await _backend.pause();
    } finally {
      value = value.copyWith(playing: false, error: value.error);
    }
  }

  Future<void> setVolume(double volume) async {
    final clamped = volume.clamp(0.0, maxVolume).toDouble();
    if (clamped > 0) _lastNonZeroVolume = clamped;
    value = value.copyWith(volume: clamped, error: value.error);
    try {
      await _backend.setVolume(clamped);
    } catch (e) {
      value = value.copyWith(error: e.toString());
    }
  }

  Future<void> toggleMute() => setVolume(value.volume > 0 ? 0 : _lastNonZeroVolume);

  Future<String> saveScreenshot() async {
    final source = _source;
    if (!_opened || source == null || !value.firstFrame) {
      throw ClipExportException(t.videoControls.clip.previewLoadingScreenshot);
    }
    if (value.screenshotting) {
      throw ClipExportException(t.videoControls.clip.screenshotInProgress);
    }

    value = value.copyWith(screenshotting: true, error: value.error);
    try {
      final outputFile = await ClipExportService.createScreenshotOutputFile(
        source,
        value.position,
        directoryProvider: screenshotDirectoryProvider,
      );
      await _backend.captureScreenshot(outputFile.path);
      return outputFile.path;
    } finally {
      value = value.copyWith(screenshotting: false, error: value.error);
    }
  }

  void hideSurfaceNow() {
    if (_surfaceHideRequested) return;
    _surfaceHideRequested = true;
    value = value.copyWith(playing: false, firstFrame: false, error: value.error);
    unawaited(_backend.hideSurfaceNow());
  }

  Future<void> seekToVideoTime(Duration position) async {
    final source = _source;
    final selection = _selection;
    if (source == null || selection == null) return;

    final target = _clampToSelection(position, selection);
    try {
      await _backend.seek(target);
      value = value.copyWith(position: target, error: value.error);
    } on ClipExportException catch (e) {
      value = value.copyWith(error: e.message);
    } catch (e) {
      value = value.copyWith(error: e.toString());
    }
  }

  void _handleBackendPosition(Duration position) {
    final selection = _selection;
    if (selection == null) {
      value = value.copyWith(position: position, error: value.error);
      return;
    }

    final clamped = _clampToSelection(position, selection);
    value = value.copyWith(position: clamped, error: value.error);

    if (position >= selection.end && value.playing) {
      unawaited(pause());
    }
  }

  Duration _clampToSelection(Duration position, ClipSelection selection) {
    if (position < selection.start) return selection.start;
    if (position > selection.end) return selection.end;
    return position;
  }

  @override
  void dispose() {
    _positionSubscription.cancel();
    _playingSubscription.cancel();
    _firstFrameSubscription.cancel();
    hideSurfaceNow();
    unawaited(_backend.dispose());
    super.dispose();
  }
}
