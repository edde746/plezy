import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/media/media_source_info.dart';

void main() {
  group('MediaSubtitleTrack label', () {
    test('prefers explicit source title over generated display title', () {
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

      expect(track.labelForIndex(0), 'Forced · ENG · SRT');
      expect(track.label, 'Forced · ENG · SRT');
    });

    test('falls back to display title when source title is empty', () {
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

      expect(track.labelForIndex(1), 'Japanese Signs/Songs · JPN · ASS');
    });
  });
}
