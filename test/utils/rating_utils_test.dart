import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/utils/rating_utils.dart';

void main() {
  setUpAll(() => LocaleSettings.setLocaleRaw('en'));

  group('ratingInfoForSource - Rotten Tomatoes', () {
    test('critic at or above the 60% tomatometer is fresh', () {
      final info = ratingInfoForSource('rottenTomatoesCritic', 6.0);
      expect(info!.assetPath, 'assets/rating_icons/rt_fresh.svg');
      expect(info.formattedValue, '60%');
    });

    test('critic below the tomatometer is rotten', () {
      final info = ratingInfoForSource('rottenTomatoesCritic', 5.9);
      expect(info!.assetPath, 'assets/rating_icons/rt_rotten.svg');
      expect(info.formattedValue, '59%');
    });

    test('audience uses the popcorn pair on the same threshold', () {
      expect(ratingInfoForSource('rottenTomatoesAudience', 6.0)!.assetPath, 'assets/rating_icons/rt_upright.svg');
      expect(ratingInfoForSource('rottenTomatoesAudience', 5.9)!.assetPath, 'assets/rating_icons/rt_spilled.svg');
    });

    test('the unsplit key follows the critic pair', () {
      expect(ratingInfoForSource('rottenTomatoes', 9.2)!.assetPath, 'assets/rating_icons/rt_fresh.svg');
    });

    test('percent rounds to a whole number', () {
      expect(ratingInfoForSource('rottenTomatoesCritic', 7.57)!.formattedValue, '76%');
    });
  });

  group('ratingInfoForSource - branded scales', () {
    test('IMDb keeps its 0-10 decimal', () {
      final info = ratingInfoForSource('imdb', 7.5);
      expect(info!.assetPath, 'assets/rating_icons/imdb.svg');
      expect(info.formattedValue, '7.5');
    });

    test('TMDB renders as a percentage', () {
      final info = ratingInfoForSource('tmdb', 6.8);
      expect(info!.assetPath, 'assets/rating_icons/tmdb.svg');
      expect(info.formattedValue, '68%');
    });
  });

  group('ratingInfoForSource - unbranded sources', () {
    test('sources without a logo get no badge so they stay label-only', () {
      for (final source in ['critic', 'audience', 'simkl', 'mal', 'anilist', 'trakt']) {
        expect(ratingInfoForSource(source, 8.0), isNull, reason: source);
      }
    });

    test('an unknown key gets no badge', () {
      expect(ratingInfoForSource('letterboxd', 8.0), isNull);
      expect(ratingInfoForSource('', 8.0), isNull);
    });
  });

  group('ratingSourceLabel', () {
    test('names every source the mappers can emit', () {
      const sources = [
        'critic',
        'audience',
        'imdb',
        'tmdb',
        'rottenTomatoes',
        'rottenTomatoesCritic',
        'rottenTomatoesAudience',
        'simkl',
        'mal',
        'anilist',
        'trakt',
      ];
      for (final source in sources) {
        expect(ratingSourceLabel(source), isNotEmpty, reason: source);
      }
    });

    test('keeps the Rotten Tomatoes panels distinguishable', () {
      expect(ratingSourceLabel('rottenTomatoesCritic'), isNot(ratingSourceLabel('rottenTomatoesAudience')));
    });

    test('returns null for an unknown key so it can be dropped rather than shown raw', () {
      expect(ratingSourceLabel('letterboxd'), isNull);
      expect(ratingSourceLabel(''), isNull);
    });
  });
}
