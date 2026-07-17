import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/player/player.dart';
import 'package:plezy/services/clip_export_service.dart';
import 'package:plezy/services/clip_preview_player_controller.dart';

ClipSource _source({bool isTranscoding = false, Duration timelineOffset = Duration.zero}) {
  return ClipSource(
    uri: 'https://example.test/video.mp4',
    isTranscoding: isTranscoding,
    timelineOffset: timelineOffset,
    duration: const Duration(minutes: 10),
    title: 'Show',
  );
}

class _FakeClipPreviewBackend implements ClipPreviewPlayerBackend {
  final _positions = StreamController<Duration>.broadcast();
  final _playing = StreamController<bool>.broadcast();
  final _firstFrames = StreamController<void>.broadcast();

  Duration? openedSourceStart;
  double? openedMaxVolume;
  final List<Duration> seeks = [];
  int playCount = 0;
  int pauseCount = 0;
  int hideSurfaceNowCount = 0;
  int releasePlayerCount = 0;
  int openCount = 0;
  final List<double> volumes = [];
  final List<String> screenshots = [];

  @override
  Player? get player => null;

  @override
  Stream<Duration> get positions => _positions.stream;

  @override
  Stream<bool> get playing => _playing.stream;

  @override
  Stream<void> get firstFrames => _firstFrames.stream;

  void emitPosition(Duration position) => _positions.add(position);
  void emitFirstFrame() => _firstFrames.add(null);

  @override
  Future<void> open({required ClipSource source, required Duration sourceStart, required double maxVolume}) async {
    openCount++;
    openedSourceStart = sourceStart;
    openedMaxVolume = maxVolume;
  }

  @override
  Future<void> play() async {
    playCount++;
  }

  @override
  Future<void> pause() async {
    pauseCount++;
  }

  @override
  Future<void> seek(Duration videoPosition) async {
    seeks.add(videoPosition);
  }

  @override
  Future<void> setVolume(double volume) async {
    volumes.add(volume);
  }

  @override
  Future<void> captureScreenshot(String outputPath) async {
    screenshots.add(outputPath);
  }

  @override
  Future<void> hideSurfaceNow() async {
    hideSurfaceNowCount++;
    await pause();
  }

  @override
  Future<void> releasePlayer() async {
    releasePlayerCount++;
  }

  @override
  Future<void> dispose() async {
    await _positions.close();
    await _playing.close();
    await _firstFrames.close();
  }
}

void main() {
  group('ClipPreviewPlayerController', () {
    test('resolves volume defaults without changing main player state', () {
      final audiblePlaying = ClipPreviewPlayerController.volumeDefaultsForMainPlayer(
        playing: true,
        volume: 60,
        savedVolume: 40,
        maxVolume: 100,
      );
      final mutedPlaying = ClipPreviewPlayerController.volumeDefaultsForMainPlayer(
        playing: true,
        volume: 0,
        savedVolume: 40,
        maxVolume: 100,
      );
      final paused = ClipPreviewPlayerController.volumeDefaultsForMainPlayer(
        playing: false,
        volume: 60,
        savedVolume: 40,
        maxVolume: 100,
      );
      final clamped = ClipPreviewPlayerController.volumeDefaultsForMainPlayer(
        playing: false,
        volume: 0,
        savedVolume: 175,
        maxVolume: 150,
      );

      expect(audiblePlaying, (initialVolume: 0, lastNonZeroVolume: 60));
      expect(mutedPlaying, (initialVolume: 40, lastNonZeroVolume: 40));
      expect(paused, (initialVolume: 60, lastNonZeroVolume: 60));
      expect(clamped, (initialVolume: 150, lastNonZeroVolume: 150));
    });

    test('builds a lossless video-only MPV screenshot command', () {
      expect(PlayerClipPreviewPlayerBackend.buildScreenshotCommand('/tmp/frame.png'), [
        'screenshot-to-file',
        '/tmp/frame.png',
        'video',
      ]);
    });

    test('direct source seeks use video timestamp unchanged', () async {
      final backend = _FakeClipPreviewBackend();
      final controller = ClipPreviewPlayerController(backend: backend);
      addTearDown(controller.dispose);

      await controller.open(_source(), const ClipSelection(start: Duration(minutes: 2), end: Duration(minutes: 3)));
      await controller.seekToVideoTime(const Duration(minutes: 2, seconds: 20));

      expect(backend.openedSourceStart, const Duration(minutes: 3));
      expect(backend.seeks.last, const Duration(minutes: 2, seconds: 20));
    });

    test('transcoded source seeks subtract timeline offset', () async {
      final backend = _FakeClipPreviewBackend();
      final controller = ClipPreviewPlayerController(backend: backend);
      addTearDown(controller.dispose);
      final source = _source(isTranscoding: true, timelineOffset: const Duration(minutes: 2));

      await controller.open(source, const ClipSelection(start: Duration(minutes: 3), end: Duration(minutes: 4)));
      await controller.seekToVideoTime(const Duration(minutes: 3, seconds: 30));

      expect(backend.openedSourceStart, const Duration(minutes: 2));
      expect(backend.seeks.last, const Duration(minutes: 3, seconds: 30));
    });

    test('pauses at selected end and replays from selected start', () async {
      final backend = _FakeClipPreviewBackend();
      final controller = ClipPreviewPlayerController(backend: backend);
      addTearDown(controller.dispose);
      const selection = ClipSelection(start: Duration(minutes: 1), end: Duration(minutes: 2));

      await controller.open(_source(), selection);
      await controller.play();
      backend.emitPosition(selection.end);
      await pumpEventQueue();

      expect(backend.pauseCount, 1);
      expect(controller.value.playing, isFalse);

      await controller.play();

      expect(backend.seeks.last, selection.start);
      expect(backend.playCount, 2);
    });

    test('applies isolated volume and restores the last level after mute', () async {
      final backend = _FakeClipPreviewBackend();
      final controller = ClipPreviewPlayerController(
        backend: backend,
        initialVolume: 0,
        lastNonZeroVolume: 65,
        maxVolume: 100,
      );
      addTearDown(controller.dispose);

      await controller.open(_source(), const ClipSelection(start: Duration(minutes: 1), end: Duration(minutes: 2)));
      await controller.toggleMute();
      await controller.setVolume(35);
      await controller.toggleMute();
      await controller.toggleMute();

      expect(backend.volumes, [0, 65, 35, 0, 35]);
      expect(controller.value.volume, 35);
      expect(backend.openedMaxVolume, 100);
    });

    test('captures a collision-safe screenshot at the current video timestamp', () async {
      final tempDir = await Directory.systemTemp.createTemp('plezy-preview-screenshot-test-');
      addTearDown(() => tempDir.delete(recursive: true));
      await File('${tempDir.path}/Show - 02m00s.png').writeAsBytes([1]);
      final backend = _FakeClipPreviewBackend();
      final controller = ClipPreviewPlayerController(
        backend: backend,
        screenshotDirectoryProvider: () async => tempDir,
      );
      addTearDown(controller.dispose);

      await controller.open(_source(), const ClipSelection(start: Duration(minutes: 1), end: Duration(minutes: 2)));
      backend.emitFirstFrame();
      await pumpEventQueue();

      final outputPath = await controller.saveScreenshot();

      expect(outputPath, '${tempDir.path}/Show - 02m00s (2).png');
      expect(backend.screenshots, [outputPath]);
      expect(controller.value.screenshotting, isFalse);
    });

    test('trim changes update the preview range without controlling playback', () async {
      final backend = _FakeClipPreviewBackend();
      final controller = ClipPreviewPlayerController(backend: backend);
      addTearDown(controller.dispose);
      const initial = ClipSelection(start: Duration(minutes: 1), end: Duration(minutes: 2));
      const trimmed = ClipSelection(start: Duration(minutes: 1, seconds: 10), end: Duration(minutes: 2));

      await controller.open(_source(), initial);
      await controller.setSelection(trimmed);

      expect(controller.selection?.start, trimmed.start);
      expect(controller.selection?.end, trimmed.end);
      expect(backend.playCount, 0);
      expect(backend.pauseCount, 0);
    });

    test('reveals the preview when the backend reports a drawable frame', () async {
      final backend = _FakeClipPreviewBackend();
      final controller = ClipPreviewPlayerController(backend: backend);
      addTearDown(controller.dispose);

      await controller.open(_source(), const ClipSelection(start: Duration(minutes: 1), end: Duration(minutes: 2)));
      expect(controller.value.firstFrame, isFalse);

      backend.emitFirstFrame();
      await pumpEventQueue();

      expect(controller.value.firstFrame, isTrue);
    });

    test('hideSurfaceNow pauses and hides through preview backend before disposal', () async {
      final backend = _FakeClipPreviewBackend();
      final controller = ClipPreviewPlayerController(backend: backend);
      addTearDown(controller.dispose);

      await controller.open(_source(), const ClipSelection(start: Duration(minutes: 1), end: Duration(minutes: 2)));
      await controller.play();

      controller.hideSurfaceNow();
      await pumpEventQueue();

      expect(backend.hideSurfaceNowCount, 1);
      expect(backend.pauseCount, 1);
      expect(controller.value.playing, isFalse);
      expect(controller.value.firstFrame, isFalse);
    });

    test('suspends and resumes the preview around an encoder using the same channel', () async {
      final backend = _FakeClipPreviewBackend();
      final controller = ClipPreviewPlayerController(backend: backend);
      addTearDown(controller.dispose);

      await controller.open(_source(), const ClipSelection(start: Duration(minutes: 1), end: Duration(minutes: 2)));
      await controller.suspendForExport();

      expect(backend.releasePlayerCount, 1);
      expect(controller.isOpen, isFalse);

      await controller.resumeAfterExport();

      expect(backend.openCount, 2);
      expect(controller.isOpen, isTrue);
    });
  });
}
