import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/plex/plex_user_profile.dart';

void main() {
  group('PlexUserProfile.fromJson', () {
    test('parses legacy array shape for language lists', () {
      final profile = PlexUserProfile.fromJson({
        'defaultAudioLanguages': ['en', 'sv'],
        'defaultSubtitleLanguages': ['sv'],
        'mediaReviewsLanguages': ['en'],
      });

      expect(profile.defaultAudioLanguages, ['en', 'sv']);
      expect(profile.defaultSubtitleLanguages, ['sv']);
      expect(profile.mediaReviewsLanguages, ['en']);
    });

    test('parses the July 2026 CSV string shape for language lists (#1488)', () {
      final profile = PlexUserProfile.fromJson({
        'defaultAudioLanguages': 'en,sv',
        'defaultSubtitleLanguages': 'en,sv',
        'mediaReviewsLanguages': 'en',
      });

      expect(profile.defaultAudioLanguages, ['en', 'sv']);
      expect(profile.defaultSubtitleLanguages, ['en', 'sv']);
      expect(profile.mediaReviewsLanguages, ['en']);
    });

    test('parses absent and null language lists as null', () {
      final profile = PlexUserProfile.fromJson({'defaultAudioLanguages': null});

      expect(profile.defaultAudioLanguages, isNull);
      expect(profile.defaultSubtitleLanguages, isNull);
      expect(profile.mediaReviewsLanguages, isNull);
    });

    test('unwraps the profile envelope and tolerates a non-map envelope', () {
      final flat = PlexUserProfile.fromJson({'defaultAudioLanguage': 'en'});
      final wrapped = PlexUserProfile.fromJson({
        'profile': {'defaultAudioLanguage': 'en'},
      });
      final garbage = PlexUserProfile.fromJson({'profile': 'garbage'});

      expect(flat.defaultAudioLanguage, 'en');
      expect(wrapped.defaultAudioLanguage, 'en');
      expect(garbage.defaultAudioLanguage, isNull);
    });

    test('singular language fields take the first entry of array/CSV drift', () {
      final csv = PlexUserProfile.fromJson({'defaultAudioLanguage': 'en,sv'});
      final array = PlexUserProfile.fromJson({
        'defaultSubtitleLanguage': ['sv', 'en'],
      });

      expect(csv.defaultAudioLanguage, 'en');
      expect(array.defaultSubtitleLanguage, 'sv');
    });

    test('scalar fields coerce from drifted types', () {
      final profile = PlexUserProfile.fromJson({
        'autoSelectAudio': 0,
        'autoSelectSubtitle': '1',
        'watchedIndicator': '2',
        'defaultSubtitleForced': {},
      });

      expect(profile.autoSelectAudio, isFalse);
      expect(profile.autoSelectSubtitle, 1);
      expect(profile.watchedIndicator, 2);
      expect(profile.defaultSubtitleForced, 1);
    });

    test('defaults() matches parsing an empty map', () {
      final parsed = PlexUserProfile.fromJson(const {});
      final defaults = PlexUserProfile.defaults();

      expect(defaults.autoSelectAudio, parsed.autoSelectAudio);
      expect(defaults.defaultAudioAccessibility, parsed.defaultAudioAccessibility);
      expect(defaults.defaultAudioLanguage, parsed.defaultAudioLanguage);
      expect(defaults.defaultAudioLanguages, parsed.defaultAudioLanguages);
      expect(defaults.defaultSubtitleLanguage, parsed.defaultSubtitleLanguage);
      expect(defaults.defaultSubtitleLanguages, parsed.defaultSubtitleLanguages);
      expect(defaults.autoSelectSubtitle, parsed.autoSelectSubtitle);
      expect(defaults.defaultSubtitleAccessibility, parsed.defaultSubtitleAccessibility);
      expect(defaults.defaultSubtitleForced, parsed.defaultSubtitleForced);
      expect(defaults.watchedIndicator, parsed.watchedIndicator);
      expect(defaults.mediaReviewsVisibility, parsed.mediaReviewsVisibility);
      expect(defaults.mediaReviewsLanguages, parsed.mediaReviewsLanguages);
    });
  });
}
