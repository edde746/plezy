import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_source_info.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/services/track_selection_service.dart';

// The container-ordinal guards in `findMpvTrackForPlexSubtitle` and
// `findPlexTrackForMpvSubtitle` look like mirrors but are not: when the probe
// has no ordinal in the container list, the Plex->MPV direction still scores by
// metadata while the MPV->Plex direction refuses to match at all. These tests
// pin that difference so the two guards are not "symmetrised".

MediaSubtitleTrack _plexSub(int id, {int? index, String? languageCode}) =>
    MediaSubtitleTrack(id: id, index: index, languageCode: languageCode, selected: false, forced: false);

SubtitleTrack _containerSub(String id, {String? lang}) =>
    SubtitleTrack(id: id, language: lang, isExternal: true, isContainer: true);

void main() {
  group('container-ordinal guard asymmetry', () {
    test('Plex->MPV keeps metadata scoring when the Plex stream has no container ordinal', () {
      final probe = _plexSub(40, index: 0, languageCode: 'eng');
      final otherPlexTracks = [_plexSub(41, index: 1, languageCode: 'eng')];
      final nativeTracks = [_containerSub('2_0', lang: 'eng')];

      expect(findMpvTrackForPlexSubtitle(probe, nativeTracks, allPlexTracks: otherPlexTracks), nativeTracks.first);
    });

    test('MPV->Plex refuses to match when the container track has no ordinal', () {
      final probe = _containerSub('2_0', lang: 'eng');
      final otherNativeTracks = [_containerSub('2_1', lang: 'eng')];
      final plexTracks = [_plexSub(40, index: 0, languageCode: 'eng')];

      expect(findPlexTrackForMpvSubtitle(probe, plexTracks, allMpvTracks: otherNativeTracks), isNull);
    });
  });
}
