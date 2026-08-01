import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/external_ids.dart';

void main() {
  group('ExternalSeasonRef.agreedSeason', () {
    test('resolves only when both providers mapped the season and agree', () {
      expect(const ExternalSeasonRef(tvdb: 3, tmdb: 3).agreedSeason, 3);
      // Fribb maps "You and I Are Polar Opposites Season 2" to TVDB season 2
      // but TMDB season 1 (a continuation at an episode offset). Which one a
      // library follows is a server setting, so there is no honest answer.
      expect(const ExternalSeasonRef(tvdb: 2, tmdb: 1).agreedSeason, isNull);
    });

    test('a missing number is not agreement', () {
      // Absence means Fribb has no mapping for that provider, so a server
      // ordered by it would number the season by data we do not have.
      expect(const ExternalSeasonRef(tvdb: 2).agreedSeason, isNull);
      expect(const ExternalSeasonRef(tmdb: 2).agreedSeason, isNull);
      expect(const ExternalSeasonRef().agreedSeason, isNull);
    });

    test('isSequel stays knowable even when the numbers disagree', () {
      // The gate cannot resolve this ref, but the year window still must be
      // dropped: a sequel's catalog year is its own, not the parent show's.
      expect(const ExternalSeasonRef(tvdb: 2, tmdb: 1).isSequel, isTrue);
      expect(const ExternalSeasonRef(tvdb: 1, tmdb: 1).isSequel, isFalse);
      expect(const ExternalSeasonRef(tmdb: 4).isSequel, isTrue);
      expect(const ExternalSeasonRef().isSequel, isFalse);
    });

    test('round-trips through JSON', () {
      const ref = ExternalSeasonRef(tvdb: 2, tmdb: 1);
      expect(ExternalSeasonRef.fromJson(ref.toJson()), ref);
      expect(ExternalSeasonRef.fromJson(const ExternalSeasonRef().toJson()).hasAny, isFalse);
    });
  });
}
