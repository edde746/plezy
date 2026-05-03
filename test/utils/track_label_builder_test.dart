import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/track_label_builder.dart';

void main() {
  group('buildTrackLabel', () {
    test('joins title, language, and extra parts with " · "', () {
      expect(
        buildTrackLabel(title: 'Director Cut', language: 'EN', extraParts: const ['AAC', '2ch'], index: 0),
        'Director Cut · EN · AAC · 2ch',
      );
    });

    test('drops null/empty title and language', () {
      expect(buildTrackLabel(title: null, language: null, extraParts: const ['AAC'], index: 0), 'AAC');
      expect(buildTrackLabel(title: '', language: '', extraParts: const ['AAC'], index: 0), 'AAC');
    });

    test('falls back to "<prefix> <index+1>" when no parts', () {
      expect(buildTrackLabel(index: 0), 'Track 1');
      expect(buildTrackLabel(index: 4), 'Track 5');
      expect(buildTrackLabel(index: 2, fallbackPrefix: 'Audio Track'), 'Audio Track 3');
    });

    test('preserves ordering: title, language, extras', () {
      expect(buildTrackLabel(title: 'A', language: 'B', extraParts: const ['C', 'D'], index: 0), 'A · B · C · D');
    });

    test('only language', () {
      expect(buildTrackLabel(language: 'FR', index: 0), 'FR');
    });

    test('only title', () {
      expect(buildTrackLabel(title: 'Commentary', index: 0), 'Commentary');
    });
  });

  group('TrackLabelBuilder.buildAudioLabel', () {
    test('combines title, uppercased language, codec, channels', () {
      expect(
        TrackLabelBuilder.buildAudioLabel(title: 'Main', language: 'en', codec: 'aac', channelsCount: 2, index: 0),
        'Main · EN · AAC · 2ch',
      );
    });

    test('uppercases language', () {
      expect(
        TrackLabelBuilder.buildAudioLabel(language: 'fr', codec: 'ac3', channelsCount: 6, index: 0),
        'FR · AC3 · 6ch',
      );
    });

    test('formats codec via CodecUtils (e.g. eac3 -> E-AC3)', () {
      final label = TrackLabelBuilder.buildAudioLabel(codec: 'eac3', index: 0);
      expect(label, 'E-AC3');
    });

    test('omits codec when null/empty', () {
      expect(TrackLabelBuilder.buildAudioLabel(language: 'en', codec: null, index: 0), 'EN');
      expect(TrackLabelBuilder.buildAudioLabel(language: 'en', codec: '', index: 0), 'EN');
    });

    test('omits channels when null', () {
      expect(TrackLabelBuilder.buildAudioLabel(language: 'en', codec: 'aac', index: 0), 'EN · AAC');
    });

    test('falls back to "Audio Track N" when nothing supplied', () {
      expect(TrackLabelBuilder.buildAudioLabel(index: 0), 'Audio Track 1');
      expect(TrackLabelBuilder.buildAudioLabel(index: 3), 'Audio Track 4');
    });

    test('zero channel count is still rendered (caller decides validity)', () {
      // Behavior check: 0 is non-null, so it appears as 0ch.
      expect(TrackLabelBuilder.buildAudioLabel(channelsCount: 0, index: 0), '0ch');
    });
  });

  group('TrackLabelBuilder.buildSubtitleLabel', () {
    test('combines title, uppercased language, friendly codec', () {
      expect(
        TrackLabelBuilder.buildSubtitleLabel(title: 'Forced', language: 'en', codec: 'subrip', index: 0),
        'Forced · EN · SRT',
      );
    });

    test('uppercases language and formats codec', () {
      expect(TrackLabelBuilder.buildSubtitleLabel(language: 'fr', codec: 'webvtt', index: 0), 'FR · VTT');
      expect(TrackLabelBuilder.buildSubtitleLabel(language: 'de', codec: 'hdmv_pgs_subtitle', index: 0), 'DE · PGS');
    });

    test('omits codec when null/empty', () {
      expect(TrackLabelBuilder.buildSubtitleLabel(language: 'en', index: 0), 'EN');
      expect(TrackLabelBuilder.buildSubtitleLabel(language: 'en', codec: '', index: 0), 'EN');
    });

    test('does not duplicate forced when the title already says forced', () {
      expect(
        TrackLabelBuilder.buildSubtitleLabel(title: 'Forced', language: 'en', codec: 'subrip', forced: true, index: 0),
        'Forced · EN · SRT',
      );
    });

    test('falls back to "Track N" with default prefix', () {
      expect(TrackLabelBuilder.buildSubtitleLabel(index: 0), 'Track 1');
      expect(TrackLabelBuilder.buildSubtitleLabel(index: 7), 'Track 8');
    });

    test('cleans raw Jellyfin/ExoPlayer subtitle metadata prefixes', () {
      expect(
        TrackLabelBuilder.buildSubtitleLabel(
          title: 'title=German - SUBRIP',
          language: 'LANG=DEU',
          codec: 'srt',
          index: 0,
        ),
        'German · DEU · SRT',
      );
      expect(
        TrackLabelBuilder.buildSubtitleLabel(
          title: 'title=English - Default - SUBRIP',
          language: 'LANG=ENG',
          codec: 'subrip',
          index: 1,
        ),
        'English - Default · ENG · SRT',
      );
    });
  });
}
