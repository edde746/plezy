import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/external_ids.dart';

void main() {
  group('ExternalIds.intersects', () {
    test('matches when any shared id form is equal', () {
      const trakt = ExternalIds(imdb: 'tt0133093', tmdb: 603);
      expect(trakt.intersects(const ExternalIds(tmdb: 603)), isTrue);
      expect(trakt.intersects(const ExternalIds(imdb: 'tt0133093', tvdb: 999)), isTrue);
    });

    test('never matches on absent or differing ids', () {
      const trakt = ExternalIds(imdb: 'tt0133093');
      expect(trakt.intersects(const ExternalIds(tmdb: 603)), isFalse);
      expect(trakt.intersects(const ExternalIds(imdb: 'tt9999999')), isFalse);
      expect(const ExternalIds().intersects(const ExternalIds()), isFalse);
    });
  });

  group('ExternalIds.jellyfinCandidateMatching', () {
    const target = ExternalIds(imdb: 'tt0133093', tmdb: 603);

    test('picks the candidate whose ProviderIds intersect, skipping others', () {
      final candidates = <Map<String, dynamic>>[
        {
          'Name': 'The Matrix Reloaded',
          'ProviderIds': {'Imdb': 'tt0234215', 'Tmdb': '604'},
        },
        {'Name': 'No provider ids'},
        {
          'Name': 'The Matrix',
          'ProviderIds': {'Tmdb': '603'},
        },
      ];
      expect(ExternalIds.jellyfinCandidateMatching(candidates, target)?['Name'], 'The Matrix');
    });

    test('returns null when nothing verifies', () {
      final candidates = <Map<String, dynamic>>[
        {
          'Name': 'Similar title, different film',
          'ProviderIds': {'Imdb': 'tt0234215'},
        },
      ];
      expect(ExternalIds.jellyfinCandidateMatching(candidates, target), isNull);
    });
  });
}
