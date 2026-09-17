import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/live_tv_support.dart';
import 'package:plezy/media/media_source_info.dart';
import 'package:plezy/models/livetv_capture_buffer.dart';
import 'package:plezy/screens/video_player/live_timeline_report.dart';

void main() {
  group('capture metadata polling', () {
    test('refreshes a paused buffer every two seconds after the startup grace period', () {
      fakeAsync((async) {
        final session = _FakeSession(_buffer(1000));
        var buffer = session.captureBuffer;
        final timer = startLiveTimelinePolling(
          interval: const Duration(seconds: 2),
          isCurrent: () => true,
          onTick: () {},
          report: () => _run(
            session,
            1,
            state: 'paused',
            currentSession: () => session,
            currentGeneration: () => 1,
            commit: (update) => buffer = update,
          ),
        );
        async.elapse(const Duration(seconds: 2));
        expect(session.states, isEmpty, reason: 'Do not reopen the startup transcode with an early heartbeat');
        async.elapse(const Duration(seconds: 1));
        session.complete(0, _buffer(1003));
        async.flushMicrotasks();
        expect(buffer.startedAt, 1003);
        async.elapse(const Duration(seconds: 1));
        session.complete(1, _buffer(1004));
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 2));
        session.complete(2, _buffer(1006));
        async.flushMicrotasks();
        expect(buffer.startedAt, 1006);
        expect(session.states, ['paused', 'paused', 'paused']);
        timer.cancel();
      });
    });

    test('slow requests do not overlap, but freshness ticks continue and polling resumes', () {
      fakeAsync((async) {
        final requests = <Completer<void>>[];
        var ticks = 0;
        final timer = startLiveTimelinePolling(
          interval: const Duration(seconds: 2),
          isCurrent: () => true,
          onTick: () => ticks++,
          report: () {
            final request = Completer<void>();
            requests.add(request);
            return request.future;
          },
        );
        async.elapse(const Duration(seconds: 10));
        expect(requests, hasLength(1));
        expect(ticks, greaterThan(1));
        requests.single.complete();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 2));
        expect(requests, hasLength(2));
        timer.cancel();
        requests.last.complete();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 10));
        expect(requests, hasLength(2));
      });
    });

    test('cancellation or obsolete ownership suppresses the delayed initial report', () {
      fakeAsync((async) {
        var reports = 0;
        var current = true;
        Timer start() => startLiveTimelinePolling(
          interval: const Duration(seconds: 2),
          isCurrent: () => current,
          onTick: () {},
          report: () async => reports++,
        );
        start().cancel();
        final obsolete = start();
        current = false;
        async.elapse(const Duration(seconds: 6));
        expect(reports, 0);
        obsolete.cancel();
      });
    });
  });

  test('live stop drains an in-flight heartbeat and rejects later progress', () async {
    final queue = LiveTimelineReportQueue();
    final session = _FakeSession(_buffer(1000));
    Future<void> report(String state, int position) => runLiveTimelineReport(
      requestSession: session,
      requestGeneration: 1,
      state: state,
      positionMs: position,
      currentSession: () => session,
      currentGeneration: () => 1,
      isMounted: () => true,
      commit: (_) {},
    );
    final playing = queue.send(stopped: false, report: () => report('playing', 100));
    final queued = queue.send(stopped: false, report: () => report('paused', 200));
    var stoppedDone = false;
    final stopped = queue
        .send(stopped: true, report: () => report('stopped', 321))
        .whenComplete(() => stoppedDone = true);
    final repeated = queue.send(stopped: true, report: () => report('stopped', 0));
    final late = queue.send(stopped: false, report: () => report('playing', 400));
    expect(session.states, ['playing']);
    session.complete(0, null);
    await playing;
    await queued;
    // Let the serialized terminal callback reach its HTTP await.
    await Future<void>.delayed(Duration.zero);
    expect(session.states, ['playing', 'stopped']);
    expect(session.positions, [100, 321]);
    expect(stoppedDone, isFalse);
    session.complete(1, null);
    await Future.wait([stopped, repeated, late]);
    expect(stoppedDone, isTrue);
    expect(session.states, ['playing', 'stopped']);
  });

  test('failed live heartbeat does not block the terminal attempt', () async {
    final queue = LiveTimelineReportQueue();
    final gate = Completer<void>();
    final sent = <String>[];
    final playing = queue.send(stopped: false, report: () => gate.future);
    final failure = expectLater(playing, throwsStateError);
    final stopped = queue.send(stopped: true, report: () async => sent.add('stopped'));
    gate.completeError(StateError('connection lost'));
    await failure;
    await stopped;
    expect(sent, ['stopped']);
  });

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
    commit: (update) => commit(update.captureBuffer!),
  );
}

CaptureBuffer _buffer(double startedAt) => CaptureBuffer(startedAt: startedAt, seekStartSeconds: 0, seekEndSeconds: 60);

class _FakeSession implements LiveTvPlaybackSession {
  _FakeSession(this.captureBuffer);

  @override
  final CaptureBuffer captureBuffer;
  final List<String> states = [];
  final List<int> positions = [];
  final List<Completer<LiveTimelineUpdate?>> _reports = [];

  void complete(int index, CaptureBuffer? buffer) =>
      _reports[index].complete(buffer == null ? null : LiveTimelineUpdate(captureBuffer: buffer));

  @override
  LiveTvBackgroundPolicy get backgroundPolicy => LiveTvBackgroundPolicy.retainSession;

  @override
  bool get canTimeShift => true;

  @override
  LiveProgramInfo get program => const LiveProgramInfo(durationMs: 999);

  @override
  Future<LiveTvPlaybackSession?> recover({required bool directStream, required bool directStreamAudio}) async => this;

  @override
  Future<LiveTimelineUpdate?> reportTimeline({
    required String state,
    required int positionMs,
    required int durationMs,
  }) {
    states.add(state);
    positions.add(positionMs);
    final completer = Completer<LiveTimelineUpdate?>();
    _reports.add(completer);
    return completer.future;
  }

  @override
  List<MediaSubtitleTrack> get subtitleTracks => const [];

  @override
  Future<String?> streamUrlAt({int? offsetSeconds, MediaSubtitleTrack? subtitleTrack}) async =>
      'https://example.invalid/live';
}
