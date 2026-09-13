import 'dart:async';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/live_tv_support.dart';
import 'package:plezy/media/live_tv_timeline.dart';
import 'package:plezy/media/media_source_info.dart';
import 'package:plezy/models/livetv_capture_buffer.dart';
import 'package:plezy/mpv/player/player_streams.dart';
import 'package:plezy/screens/video_player/live_tv_session_state.dart';
import 'package:plezy/screens/video_player/live_stream_retry.dart';
import 'package:plezy/services/live_seek_accumulator.dart';

MediaSubtitleTrack _track({required int id, int? index, String? languageCode}) =>
    MediaSubtitleTrack(id: id, index: index, languageCode: languageCode, selected: false, forced: false);

void main() {
  group('LiveTvSessionState.remapSubtitleSelection', () {
    test('null previous selection stays off', () {
      expect(LiveTvSessionState.remapSubtitleSelection([_track(id: 1)], null), isNull);
    });

    test('prefers the identical stream id', () {
      final tracks = [_track(id: 1, languageCode: 'fin'), _track(id: 2, languageCode: 'fin')];
      final remapped = LiveTvSessionState.remapSubtitleSelection(tracks, _track(id: 2, languageCode: 'fin'));
      expect(remapped!.id, 2);
    });

    test('re-tuned ids fall back to language and stream index', () {
      // A re-tune mints new stream ids; the equivalent track keeps its
      // language and index.
      final tracks = [
        _track(id: 101, index: 3, languageCode: 'fin'),
        _track(id: 102, index: 4, languageCode: 'fin'),
        _track(id: 103, index: 5, languageCode: 'swe'),
      ];
      final remapped = LiveTvSessionState.remapSubtitleSelection(tracks, _track(id: 92, index: 4, languageCode: 'fin'));
      expect(remapped!.id, 102);
    });

    test('language alone matches when the index moved', () {
      final tracks = [_track(id: 101, index: 3, languageCode: 'swe'), _track(id: 102, index: 4, languageCode: 'fin')];
      final remapped = LiveTvSessionState.remapSubtitleSelection(tracks, _track(id: 92, index: 9, languageCode: 'fin'));
      expect(remapped!.id, 102);
    });

    test('no equivalent track drops the selection', () {
      final tracks = [_track(id: 101, index: 3, languageCode: 'swe')];
      expect(LiveTvSessionState.remapSubtitleSelection(tracks, _track(id: 92, index: 4, languageCode: 'fin')), isNull);
    });
  });

  group('LiveTvSessionState.adoptSession', () {
    test('resets the subtitle selection because stream ids are tune-scoped', () {
      final state = LiveTvSessionState(null);
      state.selectedSubtitle = _track(id: 92, languageCode: 'fin');

      state.adoptSession(_FakeSession());

      expect(state.selectedSubtitle, isNull);
    });
  });

  test('retry finalization releases its owner after intent cancellation but cannot clear a newer retry', () {
    final state = LiveTvSessionState(null);
    final first = state.beginRetry();
    state.cancelClockOpens();
    state.finishRetry(first);
    expect(state.retrying, isFalse);
    final old = state.beginRetry();
    state.cancelRetry();
    final replacement = state.beginRetry();
    state.finishRetry(old);
    expect(state.retrying, isTrue);
    expect(state.ownsRetry(replacement), isTrue);
    state.finishRetry(replacement);
    expect(state.retrying, isFalse);
  });

  test('superseded asynchronous recovery releases retry status through its finalizer', () async {
    final state = LiveTvSessionState(null);
    final owner = state.beginRetry();
    final recovery = Completer<String?>();
    var intentCurrent = true;
    final discarded = <String>[];
    final result = runLiveStreamRetry<String>(
      recover: () => recovery.future,
      lookupStreamUrl: (_) async => 'unused',
      applyPlayerOptions: () async {},
      open: (_) async {},
      isCurrent: () => intentCurrent && state.ownsRetry(owner),
      adoptSession: (_) => fail('obsolete recovery adopted'),
      currentSession: () => 'old',
      discardSession: discarded.add,
      reportFailure: (_, _) => fail('obsolete failure reported'),
      onFinished: () => state.finishRetry(owner),
    );
    intentCurrent = false;
    recovery.complete('obsolete');
    expect(await result, LiveStreamRetryResult.stale);
    expect(discarded, ['obsolete']);
    expect(state.retrying, isFalse);
  });

  group('LiveTvSessionState source clock', () {
    test('subtracts a non-zero source baseline from subsequent positions', () async {
      final state = LiveTvSessionState(null);
      final generation = state.beginClockOpen(1093);
      final result = state.clockOpenResult(generation);

      expect(state.pendingTargetEpoch, 1093);
      expect(state.playbackPosition(const Duration(seconds: 52)).epoch, isNull);
      expect(state.bindClockOpen(generation, 7), isTrue);
      expect(state.calibrateClockSource(const PlayerSourceReady(sourceId: 7, position: Duration(seconds: 47))), isTrue);

      expect(await result, isTrue);
      expect(state.streamStartEpoch, 1046);
      expect(state.playbackPosition(const Duration(seconds: 52)).epoch, 1098);
    });

    test('readiness and a differing server origin remain estimates', () {
      final state = LiveTvSessionState(null);
      final generation = state.beginClockOpen(1093.25);
      state.bindClockOpen(generation, 7);
      state.calibrateClockSource(const PlayerSourceReady(sourceId: 7, position: Duration(seconds: 47)));
      final requestedEstimate = state.playbackPosition(const Duration(seconds: 52));
      expect(requestedEstimate.epoch, 1098.25);
      expect(requestedEstimate.accuracy, LiveTvTimeAccuracy.estimated);
      expect(requestedEstimate.confirmedEpoch, isNull);

      expect(
        state.adoptPlaybackStreamOrigin(
          const CaptureBuffer(startedAt: 1030.5, seekStartSeconds: 0, seekEndSeconds: 100),
          generation: state.streamGeneration,
        ),
        isTrue,
      );
      final serverEstimate = state.playbackPosition(const Duration(seconds: 52));
      expect(serverEstimate.epoch, 1082.5);
      expect(serverEstimate.accuracy, LiveTvTimeAccuracy.estimated);
      expect(serverEstimate.confirmedEpoch, isNull);
    });

    test('opening and failure retain last playback rather than requested target', () {
      final state = LiveTvSessionState(null);
      final first = state.beginClockOpen(1093);
      state.bindClockOpen(first, 7);
      state.calibrateClockSource(const PlayerSourceReady(sourceId: 7, position: Duration(seconds: 47)));
      expect(state.playbackPosition(const Duration(seconds: 52)).epoch, 1098);
      final replacement = state.beginClockOpen(1083);
      final opening = state.playbackPosition(Duration.zero);
      expect(opening.epoch, 1098);
      expect(opening.accuracy, LiveTvTimeAccuracy.stale);
      expect(opening.active, isFalse);
      expect(state.pendingTargetEpoch, 1083);
      expect(state.seekStatus, LiveTvSeekStatus.opening);
      state.failClockOpen(replacement);
      expect(state.pendingTargetEpoch, isNull);
      expect(state.seekStatus, LiveTvSeekStatus.failed);
      expect(state.playbackPosition(Duration.zero).epoch, 1098);
    });

    test('active source failure loses mapping and late sources cannot restore it', () {
      final state = LiveTvSessionState(null);
      final generation = state.beginClockOpen(1093);
      state.bindClockOpen(generation, 7);
      state.calibrateClockSource(const PlayerSourceReady(sourceId: 7, position: Duration(seconds: 47)));
      state.playbackPosition(const Duration(seconds: 52));
      state.failClockSource(const PlayerSourceFailed(8));
      expect(state.playbackPosition(const Duration(seconds: 52)).active, isTrue);
      state.failClockSource(const PlayerSourceFailed(7));
      expect(state.playbackPosition(const Duration(seconds: 60)).epoch, 1098);
      expect(state.playbackPosition(Duration.zero).accuracy, LiveTvTimeAccuracy.stale);
      expect(
        state.adoptPlaybackStreamOrigin(
          const CaptureBuffer(startedAt: 1030, seekStartSeconds: 0, seekEndSeconds: 100),
          generation: state.streamGeneration,
        ),
        isFalse,
      );
      expect(
        state.calibrateClockSource(const PlayerSourceReady(sourceId: 7, position: Duration(seconds: 60))),
        isFalse,
      );
      expect(state.playbackPosition(Duration.zero).active, isFalse);
    });

    test('invalidation cancels pending opens without inventing a playback epoch', () async {
      final state = LiveTvSessionState(null);
      final generation = state.beginClockOpen(1093);
      final result = state.clockOpenResult(generation);
      state.invalidatePlayback();
      expect(await result, isFalse);
      expect(state.bindClockOpen(generation, 7), isFalse);
      expect(state.pendingTargetEpoch, isNull);
      expect(state.playbackPosition(Duration.zero).accuracy, LiveTvTimeAccuracy.unknown);
    });

    test('unexpected backwards timestamps invalidate the active mapping', () {
      final state = LiveTvSessionState(null);
      final generation = state.beginClockOpen(1000);
      state.bindClockOpen(generation, 1);
      state.calibrateClockSource(const PlayerSourceReady(sourceId: 1, position: Duration(seconds: 52)));
      expect(state.observePlayerPosition(const Duration(seconds: 54)), isFalse);
      expect(state.observePlayerPosition(const Duration(seconds: 10)), isTrue);
      final stale = state.playbackPosition(const Duration(seconds: 10));
      expect(stale.active, isFalse);
      expect(stale.epoch, 1002);
      expect(stale.accuracy, LiveTvTimeAccuracy.stale);
    });

    test('a superseded source cannot calibrate the latest open', () async {
      final state = LiveTvSessionState(null);
      final firstGeneration = state.beginClockOpen(1085);
      final firstResult = state.clockOpenResult(firstGeneration);
      final secondGeneration = state.beginClockOpen(1070);
      final secondResult = state.clockOpenResult(secondGeneration);

      expect(state.bindClockOpen(firstGeneration, 11), isFalse);
      expect(state.bindClockOpen(secondGeneration, 12), isTrue);
      expect(
        state.calibrateClockSource(const PlayerSourceReady(sourceId: 11, position: Duration(seconds: 52))),
        isFalse,
      );
      expect(
        state.calibrateClockSource(const PlayerSourceReady(sourceId: 12, position: Duration(seconds: 40))),
        isTrue,
      );

      expect(await firstResult, isFalse);
      expect(await secondResult, isTrue);
      expect(state.playbackPosition(const Duration(seconds: 45)).epoch, 1075);
    });

    test('readiness that beats the loadfile reply calibrates on bind', () async {
      final state = LiveTvSessionState(null);
      final generation = state.beginClockOpen(1093);
      final result = state.clockOpenResult(generation);

      expect(
        state.calibrateClockSource(const PlayerSourceReady(sourceId: 7, position: Duration(seconds: 47))),
        isFalse,
      );
      expect(state.pendingTargetEpoch, 1093);
      expect(state.playbackPosition(const Duration(seconds: 52)).epoch, isNull);

      expect(state.bindClockOpen(generation, 7), isTrue);
      expect(await result, isTrue);
      expect(state.streamStartEpoch, 1046);
      expect(state.playbackPosition(const Duration(seconds: 52)).epoch, 1098);
    });

    test('a failure that beats the loadfile reply fails the open on bind', () async {
      final state = LiveTvSessionState(null);
      final generation = state.beginClockOpen(1093);
      final result = state.clockOpenResult(generation);

      state.failClockSource(const PlayerSourceFailed(7));
      expect(state.bindClockOpen(generation, 7), isFalse);

      expect(await result, isFalse);
      expect(state.pendingStreamEpoch, isNull);
      expect(
        state.calibrateClockSource(const PlayerSourceReady(sourceId: 7, position: Duration(seconds: 47))),
        isFalse,
      );
    });

    test('a rejected first load cannot claim the second seek\'s source', () async {
      final state = LiveTvSessionState(null)..streamStartEpoch = 1000;
      final firstGeneration = state.beginClockOpen(1085);
      final firstResult = state.clockOpenResult(firstGeneration);
      final secondGeneration = state.beginClockOpen(1075);
      final secondResult = state.clockOpenResult(secondGeneration);

      // The second load's source reports before either reply lands.
      state.calibrateClockSource(const PlayerSourceReady(sourceId: 12, position: Duration(seconds: 40)));
      // mpv rejected the first loadfile: no source ever existed for it.
      state.failClockOpen(firstGeneration);
      expect(await firstResult, isFalse);
      expect(state.pendingTargetEpoch, 1075);
      expect(state.playbackPosition(const Duration(seconds: 40)).epoch, isNull);

      expect(state.bindClockOpen(secondGeneration, 12), isTrue);
      expect(await secondResult, isTrue);
      expect(state.streamStartEpoch, 1035);
      expect(state.playbackPosition(const Duration(seconds: 45)).epoch, 1080);
    });

    test('an unregistered open on the same player is invisible to clock binding', () async {
      final state = LiveTvSessionState(null);
      final firstGeneration = state.beginClockOpen(1085);
      expect(state.bindClockOpen(firstGeneration, 11), isTrue);
      state.calibrateClockSource(const PlayerSourceReady(sourceId: 11, position: Duration(seconds: 10)));
      expect(state.streamStartEpoch, 1075);

      // A live-edge re-open registers no clock generation; its source reports
      // and is never claimed.
      state.calibrateClockSource(const PlayerSourceReady(sourceId: 12, position: Duration(seconds: 3)));
      expect(state.streamStartEpoch, 1075);

      final secondGeneration = state.beginClockOpen(1070);
      final secondResult = state.clockOpenResult(secondGeneration);
      expect(state.bindClockOpen(secondGeneration, 13), isTrue);
      expect(state.pendingTargetEpoch, 1070);
      expect(state.playbackPosition(const Duration(seconds: 5)).epoch, 1085);
      expect(
        state.calibrateClockSource(const PlayerSourceReady(sourceId: 13, position: Duration(seconds: 40))),
        isTrue,
      );
      expect(await secondResult, isTrue);
      expect(state.streamStartEpoch, 1030);
    });

    test('unclaimed source reports are bounded to the most recent sources', () async {
      final state = LiveTvSessionState(null);
      final generation = state.beginClockOpen(1093);
      final result = state.clockOpenResult(generation);

      state.calibrateClockSource(const PlayerSourceReady(sourceId: 1, position: Duration(seconds: 47)));
      for (var sourceId = 2; sourceId <= 9; sourceId++) {
        state.calibrateClockSource(PlayerSourceReady(sourceId: sourceId, position: Duration.zero));
      }

      expect(state.bindClockOpen(generation, 1), isTrue);
      expect(state.pendingTargetEpoch, 1093);
      expect(state.playbackPosition(const Duration(seconds: 52)).epoch, isNull);
      expect(state.calibrateClockSource(const PlayerSourceReady(sourceId: 1, position: Duration(seconds: 47))), isTrue);
      expect(await result, isTrue);
    });

    test('a calibration timeout clears pending intent but permits late readiness', () async {
      final state = LiveTvSessionState(null);
      final generation = state.beginClockOpen(1093);
      final result = state.clockOpenResult(generation);
      state.bindClockOpen(generation, 7);

      state.timeoutClockOpen(generation);
      expect(state.pendingTargetEpoch, isNull);

      expect(await result, isFalse);
      expect(state.pendingTargetEpoch, isNull);
      expect(state.playbackPosition(const Duration(seconds: 52)).epoch, isNull);
      expect(state.calibrateClockSource(const PlayerSourceReady(sourceId: 7, position: Duration(seconds: 47))), isTrue);
      expect(state.playbackPosition(const Duration(seconds: 52)).epoch, 1098);
    });

    test('a timed-out open still binds when its loadfile reply arrives late', () async {
      final state = LiveTvSessionState(null);
      final generation = state.beginClockOpen(1093);
      final result = state.clockOpenResult(generation);

      state.timeoutClockOpen(generation);
      expect(await result, isFalse);
      state.calibrateClockSource(const PlayerSourceReady(sourceId: 7, position: Duration(seconds: 47)));
      expect(state.pendingTargetEpoch, isNull);
      expect(state.playbackPosition(const Duration(seconds: 52)).epoch, isNull);

      expect(state.bindClockOpen(generation, 7), isTrue);
      expect(state.playbackPosition(const Duration(seconds: 52)).epoch, 1098);
    });

    test('a zero-based source preserves the existing epoch mapping', () async {
      final state = LiveTvSessionState(null);
      final generation = state.beginClockOpen(1093);
      final result = state.clockOpenResult(generation);
      state.bindClockOpen(generation, 7);
      state.calibrateClockSource(const PlayerSourceReady(sourceId: 7, position: Duration.zero));

      expect(await result, isTrue);
      expect(state.playbackPosition(const Duration(seconds: 5)).epoch, 1098);
    });

    test('two backward skips compound from the calibrated source clock', () {
      fakeAsync((async) {
        final state = LiveTvSessionState(null)..streamStartEpoch = 1000;
        final initial = state.beginClockOpen(1000);
        state.bindClockOpen(initial, 99);
        state.calibrateClockSource(const PlayerSourceReady(sourceId: 99, position: Duration.zero));
        var position = const Duration(seconds: 100);
        var sourceId = 0;
        final requestedEpochs = <double>[];
        final accumulator = LiveSeekAccumulator(
          seek: (targetEpoch) async {
            requestedEpochs.add(targetEpoch);
            final generation = state.beginClockOpen(targetEpoch);
            final result = state.clockOpenResult(generation);
            final currentSourceId = ++sourceId;
            state.bindClockOpen(generation, currentSourceId);
            if (requestedEpochs.length == 1) {
              state.calibrateClockSource(
                PlayerSourceReady(sourceId: currentSourceId, position: const Duration(seconds: 52)),
              );
              position = const Duration(seconds: 57);
            } else {
              state.calibrateClockSource(
                PlayerSourceReady(sourceId: currentSourceId, position: const Duration(seconds: 40)),
              );
              position = const Duration(seconds: 45);
            }
            return result;
          },
          currentEpoch: () => state.playbackPosition(position).epoch,
          bounds: () => const LiveSeekBounds(startEpoch: 0, endEpoch: 2000),
          debounce: Duration.zero,
        );

        accumulator.seekBy(-15);
        async.elapse(Duration.zero);
        async.flushMicrotasks();
        expect(requestedEpochs, [1085]);
        expect(state.playbackPosition(position).epoch, 1090);

        accumulator.seekBy(-15);
        async.elapse(Duration.zero);
        async.flushMicrotasks();
        expect(requestedEpochs, [1085, 1075]);
        expect(state.playbackPosition(position).epoch, 1080);

        accumulator.dispose();
      });
    });
  });

  group('LiveTvSessionState stream anchor', () {
    const capture = CaptureBuffer(startedAt: 1000, seekStartSeconds: 0, seekEndSeconds: 40);

    test('a live-edge open anchors on the capture edge, not wall clock', () {
      final state = LiveTvSessionState(null);

      state.markStreamRestartedAtLiveEdge(capture);

      expect(state.streamStartEpoch, 1040);
      expect(state.playbackPosition(const Duration(seconds: 10)).accuracy, LiveTvTimeAccuracy.unknown);
    });

    test('a heartbeat re-anchors the clock on the playback transcode origin', () {
      final state = LiveTvSessionState(null)..markStreamRestartedAtLiveEdge(capture);
      final generation = state.beginClockOpen(1040);
      state.bindClockOpen(generation, 1);
      state.calibrateClockSource(const PlayerSourceReady(sourceId: 1, position: Duration.zero));
      final playback = CaptureBuffer(startedAt: 1027.5, seekStartSeconds: 0.033, seekEndSeconds: 12);

      expect(state.adoptPlaybackStreamOrigin(playback, generation: state.streamGeneration), isTrue);

      // Server coordinates change the estimate, without confirming a landing.
      expect(state.playbackPosition(const Duration(seconds: 20)).epoch, 1047.5);
      expect(state.adoptPlaybackStreamOrigin(playback, generation: state.streamGeneration), isFalse);
    });

    test('a heartbeat dispatched before a re-open cannot anchor the replacement stream', () async {
      final state = LiveTvSessionState(null)..streamStartEpoch = 1040;
      final staleGeneration = state.streamGeneration;
      state.streamGeneration++;
      final generation = state.beginClockOpen(990);
      final result = state.clockOpenResult(generation);
      state.bindClockOpen(generation, 3);
      state.calibrateClockSource(const PlayerSourceReady(sourceId: 3, position: Duration.zero));
      expect(await result, isTrue);

      final old = CaptureBuffer(startedAt: 1027.5, seekStartSeconds: 0, seekEndSeconds: 60);
      expect(state.adoptPlaybackStreamOrigin(old, generation: staleGeneration), isFalse);
      expect(state.playbackPosition(Duration.zero).epoch, 990);
    });

    test('a heartbeat cannot re-anchor while an open is still calibrating', () {
      final state = LiveTvSessionState(null)..streamStartEpoch = 1040;
      state.beginClockOpen(990);

      final old = CaptureBuffer(startedAt: 1027.5, seekStartSeconds: 0, seekEndSeconds: 60);
      expect(state.adoptPlaybackStreamOrigin(old, generation: state.streamGeneration), isFalse);
      expect(state.pendingTargetEpoch, 990);
      expect(state.playbackPosition(const Duration(seconds: 5)).epoch, isNull);
    });
  });
}

class _FakeSession implements LiveTvPlaybackSession {
  @override
  LiveTvBackgroundPolicy get backgroundPolicy => LiveTvBackgroundPolicy.retainSession;

  @override
  CaptureBuffer? get captureBuffer => null;

  @override
  bool get canTimeShift => false;

  @override
  LiveProgramInfo get program => LiveProgramInfo.none;

  @override
  List<MediaSubtitleTrack> get subtitleTracks => const [];

  @override
  Future<LiveTimelineUpdate?> reportTimeline({
    required String state,
    required int positionMs,
    required int durationMs,
  }) => Future.value(null);

  @override
  Future<LiveTvPlaybackSession?> recover({required bool directStream, required bool directStreamAudio}) =>
      Future.value(this);

  @override
  Future<String?> streamUrlAt({int? offsetSeconds, MediaSubtitleTrack? subtitleTrack}) => Future.value(null);
}
