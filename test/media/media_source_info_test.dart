import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/media/media_source_info.dart';
import 'package:vibe_stream/utils/track_label_builder.dart';

void main() {
  group('MediaSubtitleTrack label', () {
    test('language leads; a bare "Forced" title folds into the suffix', () {
      final track = MediaSubtitleTrack(
        id: 401,
        index: 0,
        codec: 'srt',
        languageCode: 'eng',
        title: 'Forced',
        displayTitle: 'English (SRT)',
        selected: false,
        forced: true,
      );

      expect(track.labelForIndex(0), const TrackLabel('English (Forced)', 'SRT'));
      expect(track.label, const TrackLabel('English (Forced)', 'SRT'));
    });

    test('resolves the language name even when the source title is blank', () {
      final track = MediaSubtitleTrack(
        id: 402,
        index: 1,
        codec: 'ass',
        languageCode: 'jpn',
        title: ' ',
        displayTitle: 'Japanese Signs/Songs',
        selected: false,
        forced: false,
      );

      expect(track.labelForIndex(1), const TrackLabel('Japanese', 'ASS'));
    });

    test('falls back to display title when nothing else is available', () {
      final track = MediaSubtitleTrack(
        id: 403,
        index: 2,
        displayTitle: 'Director Commentary',
        selected: false,
        forced: false,
      );

      expect(track.labelForIndex(2), const TrackLabel('Director Commentary'));
    });
  });

  group('MediaAudioTrack label', () {
    test('builds from stream fields, ignoring the server displayTitle', () {
      final track = MediaAudioTrack(
        id: 301,
        index: 1,
        codec: 'eac3',
        language: 'English',
        languageCode: 'eng',
        title: null,
        displayTitle: 'English (EAC3 5.1)',
        channels: 6,
        selected: true,
      );

      expect(track.label, const TrackLabel('English', 'E-AC3 · 5.1'));
    });

    test('server language name wins over an unmappable code', () {
      final track = MediaAudioTrack(
        id: 302,
        index: 2,
        codec: 'aac',
        language: 'Filipino',
        languageCode: 'fil',
        channels: 2,
        selected: false,
      );

      expect(track.label, const TrackLabel('Filipino', 'AAC · Stereo'));
    });

    test('falls back to displayTitle when stream fields are missing', () {
      final track = MediaAudioTrack(id: 303, index: 3, displayTitle: 'Surround (EAC3)', selected: false);

      expect(track.label, const TrackLabel('Surround (EAC3)'));
    });

    test('fallback index is clamped for zero-indexed streams', () {
      final track = MediaAudioTrack(id: 0, index: 0, selected: false);

      expect(track.label, const TrackLabel('Audio Track 1'));
    });
  });
}
