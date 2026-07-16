import 'dart:async';

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
  final List<Duration> seeks = [];
  int playCount = 0;
  int pauseCount = 0;
  int hideSurfaceNowCount = 0;
  int releasePlayerCount = 0;
  int openCount = 0;

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
  Future<void> open({required ClipSource source, required Duration sourceStart}) async {
    openCount++;
    openedSourceStart = sourceStart;
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
    test('direct source seeks use video timestamp unchanged', () async {
      final backend = _FakeClipPreviewBackend();
      final controller = ClipPreviewPlayerController(backend: backend);
      addTearDown(controller.dispose);

      await controller.open(_source(), const ClipSelection(start: Duration(minutes: 2), end: Duration(minutes: 3)));
      await controller.seekToVideoTime(const Duration(minutes: 2, seconds: 20));

      expect(backend.openedSourceStart, const Duration(minutes: 2));
      expect(backend.seeks.last, const Duration(minutes: 2, seconds: 20));
    });

    test('transcoded source seeks subtract timeline offset', () async {
      final backend = _FakeClipPreviewBackend();
      final controller = ClipPreviewPlayerController(backend: backend);
      addTearDown(controller.dispose);
      final source = _source(isTranscoding: true, timelineOffset: const Duration(minutes: 2));

      await controller.open(source, const ClipSelection(start: Duration(minutes: 3), end: Duration(minutes: 4)));
      await controller.seekToVideoTime(const Duration(minutes: 3, seconds: 30));

      expect(backend.openedSourceStart, const Duration(minutes: 1));
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
