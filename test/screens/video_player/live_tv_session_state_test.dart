import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/live_tv_support.dart';
import 'package:plezy/media/media_source_info.dart';
import 'package:plezy/models/livetv_capture_buffer.dart';
import 'package:plezy/screens/video_player/live_tv_session_state.dart';

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
