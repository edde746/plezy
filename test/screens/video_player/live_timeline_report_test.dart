import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/live_tv_support.dart';
import 'package:plezy/media/media_source_info.dart';
import 'package:plezy/models/livetv_capture_buffer.dart';
import 'package:plezy/screens/video_player/live_timeline_report.dart';

void main() {
  group('runLiveTimelineReport', () {
    test('late pre-channel heartbeat cannot replace adopted channel buffer', () async {
      final bufferA = _buffer(1000);
      final bufferB = _buffer(2000);
      final freshBufferB = _buffer(2100);
      final sessionA = _FakeSession(bufferA);
      final sessionB = _FakeSession(bufferB);
      LiveTvPlaybackSession? currentSession = sessionA;
      var generation = 1;
      var currentBuffer = bufferA;
      var commits = 0;

      final oldHeartbeat = _run(
        sessionA,
        generation,
        state: 'playing',
        currentSession: () => currentSession,
        currentGeneration: () => generation,
        commit: (buffer) {
          commits++;
          currentBuffer = buffer;
        },
      );
      generation++;
      final stopped = _run(
        sessionA,
        generation,
        state: 'stopped',
        currentSession: () => currentSession,
        currentGeneration: () => generation,
        commit: (buffer) {
          commits++;
          currentBuffer = buffer;
        },
      );
      sessionA.complete(1, _buffer(1200));
      await stopped;

      currentSession = sessionB;
      currentBuffer = bufferB;
      generation++;
      sessionA.complete(0, _buffer(1300));
      await oldHeartbeat;

      expect(sessionA.states, ['playing', 'stopped']);
      expect(commits, 0);
      expect(currentBuffer, same(bufferB));

      final currentHeartbeat = _run(
        sessionB,
        generation,
        state: 'playing',
        currentSession: () => currentSession,
        currentGeneration: () => generation,
        commit: (buffer) {
          commits++;
          currentBuffer = buffer;
        },
      );
      sessionB.complete(0, freshBufferB);
      await currentHeartbeat;
      expect(commits, 1);
      expect(currentBuffer, same(freshBufferB));
    });

    test('session replacement invalidates report without generation change', () async {
      final sessionA = _FakeSession(_buffer(1000));
      final sessionB = _FakeSession(_buffer(2000));
      LiveTvPlaybackSession? currentSession = sessionA;
      const generation = 4;
      var commits = 0;

      final report = _run(
        sessionA,
        generation,
        state: 'playing',
        currentSession: () => currentSession,
        currentGeneration: () => generation,
        commit: (_) => commits++,
      );
      currentSession = sessionB;
      sessionA.complete(0, _buffer(1100));
      await report;

      expect(commits, 0);
    });

    test('generation change invalidates report for the same session', () async {
      final session = _FakeSession(_buffer(1000));
      final currentSession = session;
      var generation = 8;
      var commits = 0;

      final report = _run(
        session,
        generation,
        state: 'paused',
        currentSession: () => currentSession,
        currentGeneration: () => generation,
        commit: (_) => commits++,
      );
      generation++;
      session.complete(0, _buffer(1100));
      await report;

      expect(commits, 0);
    });

    test('terminal and unmounted responses never commit but are still sent', () async {
      final session = _FakeSession(_buffer(1000));
      var mounted = true;
      var commits = 0;

      final stopped = _run(
        session,
        1,
        state: 'stopped',
        currentSession: () => session,
        currentGeneration: () => 1,
        isMounted: () => mounted,
        commit: (_) => commits++,
      );
      session.complete(0, _buffer(1100));
      await stopped;

      final playing = _run(
        session,
        1,
        state: 'playing',
        currentSession: () => session,
        currentGeneration: () => 1,
        isMounted: () => mounted,
        commit: (_) => commits++,
      );
      mounted = false;
      session.complete(1, _buffer(1200));
      await playing;

      expect(session.states, ['stopped', 'playing']);
      expect(commits, 0);
    });
  });
}

Future<void> _run(
  LiveTvPlaybackSession session,
  int generation, {
  required String state,
  required LiveTvPlaybackSession? Function() currentSession,
  required int Function() currentGeneration,
  bool Function()? isMounted,
  required void Function(CaptureBuffer) commit,
}) {
  return runLiveTimelineReport(
    requestSession: session,
    requestGeneration: generation,
    state: state,
    positionMs: 321,
    currentSession: currentSession,
    currentGeneration: currentGeneration,
    isMounted: isMounted ?? () => true,
    commit: commit,
  );
}

CaptureBuffer _buffer(double startedAt) => CaptureBuffer(startedAt: startedAt, seekStartSeconds: 0, seekEndSeconds: 60);

class _FakeSession implements LiveTvPlaybackSession {
  _FakeSession(this.captureBuffer);

  @override
  final CaptureBuffer captureBuffer;
  final List<String> states = [];
  final List<Completer<CaptureBuffer?>> _reports = [];

  void complete(int index, CaptureBuffer? buffer) => _reports[index].complete(buffer);

  @override
  LiveTvBackgroundPolicy get backgroundPolicy => LiveTvBackgroundPolicy.retainSession;

  @override
  bool get canTimeShift => true;

  @override
  LiveProgramInfo get program => const LiveProgramInfo(durationMs: 999);

  @override
  Future<LiveTvPlaybackSession?> recover({required bool directStream, required bool directStreamAudio}) async => this;

  @override
  Future<CaptureBuffer?> reportTimeline({required String state, required int positionMs, required int durationMs}) {
    states.add(state);
    final completer = Completer<CaptureBuffer?>();
    _reports.add(completer);
    return completer.future;
  }

  @override
  List<MediaSubtitleTrack> get subtitleTracks => const [];

  @override
  Future<String?> streamUrlAt({int? offsetSeconds, MediaSubtitleTrack? subtitleTrack}) async =>
      'https://example.invalid/live';
}
