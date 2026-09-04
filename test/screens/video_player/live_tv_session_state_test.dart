import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/live_tv_support.dart';
import 'package:plezy/media/media_source_info.dart';
import 'package:plezy/models/livetv_capture_buffer.dart';
import 'package:plezy/mpv/player/player_streams.dart';
import 'package:plezy/screens/video_player/live_tv_session_state.dart';
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

  group('LiveTvSessionState source clock', () {
    test('subtracts a non-zero source baseline from subsequent positions', () async {
      final state = LiveTvSessionState(null);
      final generation = state.beginClockOpen(1093);
      final result = state.clockOpenResult(generation);

      expect(state.epochForPosition(const Duration(seconds: 52)), 1093);
      expect(state.bindClockSource(const PlayerSourceStarted(7)), isTrue);
      expect(state.calibrateClockSource(const PlayerSourceReady(sourceId: 7, position: Duration(seconds: 47))), isTrue);

      expect(await result, isTrue);
      expect(state.streamStartEpoch, 1046);
      expect(state.epochForPosition(const Duration(seconds: 52)), 1098);
    });

    test('a superseded source cannot calibrate the latest open', () async {
      final state = LiveTvSessionState(null);
      final firstGeneration = state.beginClockOpen(1085);
      final firstResult = state.clockOpenResult(firstGeneration);
      final secondGeneration = state.beginClockOpen(1070);
      final secondResult = state.clockOpenResult(secondGeneration);

      expect(state.bindClockSource(const PlayerSourceStarted(11)), isFalse);
      expect(state.bindClockSource(const PlayerSourceStarted(12)), isTrue);
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
      expect(state.epochForPosition(const Duration(seconds: 45)), 1075);
    });

    test('a calibration timeout keeps the target until late readiness arrives', () async {
      final state = LiveTvSessionState(null);
      final generation = state.beginClockOpen(1093);
      final result = state.clockOpenResult(generation);
      state.bindClockSource(const PlayerSourceStarted(7));

      state.timeoutClockOpen(generation);

      expect(await result, isFalse);
      expect(state.epochForPosition(const Duration(seconds: 52)), 1093);
      expect(state.calibrateClockSource(const PlayerSourceReady(sourceId: 7, position: Duration(seconds: 47))), isTrue);
      expect(state.epochForPosition(const Duration(seconds: 52)), 1098);
    });

    test('a zero-based source preserves the existing epoch mapping', () async {
      final state = LiveTvSessionState(null);
      final generation = state.beginClockOpen(1093);
      final result = state.clockOpenResult(generation);
      state.bindClockSource(const PlayerSourceStarted(7));
      state.calibrateClockSource(const PlayerSourceReady(sourceId: 7, position: Duration.zero));

      expect(await result, isTrue);
      expect(state.epochForPosition(const Duration(seconds: 5)), 1098);
    });

    test('two backward skips compound from the calibrated source clock', () {
      fakeAsync((async) {
        final state = LiveTvSessionState(null)..streamStartEpoch = 1000;
        var position = const Duration(seconds: 100);
        var sourceId = 0;
        final requestedEpochs = <int>[];
        final accumulator = LiveSeekAccumulator(
          seek: (targetEpoch) async {
            requestedEpochs.add(targetEpoch);
            final generation = state.beginClockOpen(targetEpoch);
            final result = state.clockOpenResult(generation);
            final currentSourceId = ++sourceId;
            state.bindClockSource(PlayerSourceStarted(currentSourceId));
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
          currentEpoch: () => state.epochForPosition(position),
          bounds: () => (start: 0, end: 2000),
          debounce: Duration.zero,
        );

        accumulator.seekBy(-15);
        async.elapse(Duration.zero);
        async.flushMicrotasks();
        expect(requestedEpochs, [1085]);
        expect(state.epochForPosition(position), 1090);

        accumulator.seekBy(-15);
        async.elapse(Duration.zero);
        async.flushMicrotasks();
        expect(requestedEpochs, [1085, 1075]);
        expect(state.epochForPosition(position), 1080);

        accumulator.dispose();
      });
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
  Future<CaptureBuffer?> reportTimeline({required String state, required int positionMs, required int durationMs}) =>
      Future.value(null);

  @override
  Future<LiveTvPlaybackSession?> recover({required bool directStream, required bool directStreamAudio}) =>
      Future.value(this);

  @override
  Future<String?> streamUrlAt({int? offsetSeconds, MediaSubtitleTrack? subtitleTrack}) => Future.value(null);
}
