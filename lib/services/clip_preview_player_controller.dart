import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../mpv/models.dart';
import '../mpv/player/player.dart';
import '../mpv/player/video_rect_support.dart';
import 'clip_export_service.dart';

class ClipPreviewPlayerState {
  final Duration position;
  final bool playing;
  final bool firstFrame;
  final String? error;

  const ClipPreviewPlayerState({
    this.position = Duration.zero,
    this.playing = false,
    this.firstFrame = false,
    this.error,
  });

  ClipPreviewPlayerState copyWith({Duration? position, bool? playing, bool? firstFrame, String? error}) {
    return ClipPreviewPlayerState(
      position: position ?? this.position,
      playing: playing ?? this.playing,
      firstFrame: firstFrame ?? this.firstFrame,
      error: error,
    );
  }
}

abstract class ClipPreviewPlayerBackend {
  Player? get player;
  Stream<Duration> get positions;
  Stream<bool> get playing;
  Stream<void> get firstFrames;

  Future<void> open({required ClipSource source, required Duration sourceStart});

  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration videoPosition);
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
  Future<void> open({required ClipSource source, required Duration sourceStart}) async {
    final player = _ensurePlayer();
    await player.setProperty('cache', 'yes');
    await player.setProperty('cache-on-disk', 'yes');
    await player.setProperty('cache-secs', '300');
    await player.setProperty('demuxer-max-bytes', '268435456');
    await player.setProperty('demuxer-max-back-bytes', '268435456');
    await player.setProperty('sid', 'no');
    await player.setProperty('secondary-sid', 'no');
    await player.open(
      Media(source.uri, headers: source.headers, start: sourceStart),
      play: false,
      timelineOffset: source.isTranscoding ? source.timelineOffset : Duration.zero,
      timelineDuration: source.duration,
    );
    await player.setVolume(0);
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
  late final StreamSubscription<Duration> _positionSubscription;
  late final StreamSubscription<bool> _playingSubscription;
  late final StreamSubscription<void> _firstFrameSubscription;

  ClipSource? _source;
  ClipSelection? _selection;
  bool _opened = false;
  bool _surfaceHideRequested = false;

  ClipPreviewPlayerController({ClipPreviewPlayerBackend? backend})
    : _backend = backend ?? PlayerClipPreviewPlayerBackend(),
      super(const ClipPreviewPlayerState()) {
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

  Future<void> open(ClipSource source, ClipSelection selection) async {
    final clamped = selection.clampedTo(source.duration);
    _source = source;
    _selection = clamped;
    _opened = false;
    _surfaceHideRequested = false;
    value = ClipPreviewPlayerState(position: clamped.start);

    try {
      final sourceStart = ClipExportService.sourceStartForPosition(source, clamped.start);
      await _backend.open(source: source, sourceStart: sourceStart);
      _opened = true;
      if (_surfaceHideRequested) {
        unawaited(_backend.hideSurfaceNow());
        return;
      }
      await seekToVideoTime(clamped.start);
    } on MissingPluginException {
      value = value.copyWith(error: 'Clip preview playback is not available in this build.');
    } on PlatformException catch (e) {
      value = value.copyWith(error: e.message ?? 'Clip preview playback failed.');
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

  Future<void> suspendForExport() async {
    _opened = false;
    value = value.copyWith(playing: false, firstFrame: false, error: value.error);
    await _backend.releasePlayer();
  }

  Future<void> resumeAfterExport() async {
    if (_surfaceHideRequested) return;
    final source = _source;
    final selection = _selection;
    if (source == null || selection == null) return;
    await open(source, selection);
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
