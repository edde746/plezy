import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/title_match_candidates.dart';

void main() {
  group('stripSeasonSuffix', () {
    test('drops every sequel suffix shape seen on MAL/AniList', () {
      final cases = <String, String>{
        'You and I Are Polar Opposites Season 2': 'You and I Are Polar Opposites',
        'Mushoku Tensei: Jobless Reincarnation Season 2': 'Mushoku Tensei: Jobless Reincarnation',
        '[Oshi no Ko] 2nd Season': '[Oshi no Ko]',
        'The Duke of Death and His Maid 3rd Season': 'The Duke of Death and His Maid',
        'My Hero Academia FINAL SEASON': 'My Hero Academia',
        'Dr. STONE: SCIENCE FUTURE Part 2': 'Dr. STONE: SCIENCE FUTURE',
        'Dr. STONE SCIENCE FUTURE Cour 2': 'Dr. STONE SCIENCE FUTURE',
        'Unnamed Memory Act.2': 'Unnamed Memory',
        'Kekkon Yubiwa Monogatari II': 'Kekkon Yubiwa Monogatari',
        'Isekai Quartet 3': 'Isekai Quartet',
      };
      for (final entry in cases.entries) {
        expect(stripSeasonSuffix(entry.key), entry.value, reason: entry.key);
      }
    });

    test('collapses stacked suffixes in one pass', () {
      // Truncating from the FIRST marker is what makes these single-shot.
      expect(
        stripSeasonSuffix('Mushoku Tensei: Jobless Reincarnation Season 2 Part 2'),
        'Mushoku Tensei: Jobless Reincarnation',
      );
      expect(stripSeasonSuffix('JUJUTSU KAISEN Season 3: The Culling Game Part 1'), 'JUJUTSU KAISEN');
      expect(stripSeasonSuffix('Solo Leveling Season 2 -Arise from the Shadow-'), 'Solo Leveling');
      expect(
        stripSeasonSuffix('Classroom of the Elite 4th Season: Second Year, First Semester'),
        'Classroom of the Elite',
      );
    });

    test('returns null when the title carries no sequel suffix', () {
      expect(stripSeasonSuffix('Frieren: Beyond Journey\'s End'), isNull);
      expect(stripSeasonSuffix('Cowboy Bebop'), isNull);
      // Stripping must not consume the whole title.
      expect(stripSeasonSuffix('86'), isNull);
    });

    test('does not truncate a title whose trailing number is part of its name', () {
      expect(stripSeasonSuffix('Kaiju No. 8'), isNull);
      expect(stripSeasonSuffix('Mob Psycho 100'), 'Mob Psycho');
      expect(stripSeasonSuffix('Vol. 3'), isNull);
    });
  });

  group('titleMatchCandidates', () {
    test('emits a title immediately followed by its stripped form', () {
      final candidates = titleMatchCandidates([
        'You and I Are Polar Opposites Season 2',
        'Seihantai na Kimi to Boku 2nd Season',
      ]);
      // Capped at two, so the second provider title never gets a slot — the
      // stripped form of the first is worth far more than an alias.
      expect(candidates, ['You and I Are Polar Opposites Season 2', 'You and I Are Polar Opposites']);
    });

    test('honours a wider cap by interleaving, never by listing raw titles first', () {
      final candidates = titleMatchCandidates([
        'You and I Are Polar Opposites Season 2',
        'Seihantai na Kimi to Boku 2nd Season',
      ], limit: 4);
      expect(candidates, [
        'You and I Are Polar Opposites Season 2',
        'You and I Are Polar Opposites',
        'Seihantai na Kimi to Boku 2nd Season',
        'Seihantai na Kimi to Boku',
      ]);
    });
    test('normalizes typographic punctuation both backends miss on', () {
      // Verified live: Plex and Jellyfin both return 0 for the curly form.
      expect(titleMatchCandidates(['Frieren: Beyond Journey\u2019s End']), ["Frieren: Beyond Journey's End"]);
      expect(titleMatchCandidates(['Kaguya-sama \u2013 Love is War']), ['Kaguya-sama - Love is War']);
    });

    test('drops nulls, blanks and case-insensitive duplicates', () {
      final candidates = titleMatchCandidates([
        'Bocchi the Rock!',
        null,
        '   ',
        'BOCCHI THE ROCK!',
        'Bocchi the Rock!',
      ]);
      expect(candidates, ['Bocchi the Rock!']);
    });

    test('does not emit a stripped form that duplicates a provider title', () {
      final candidates = titleMatchCandidates(['Kaiju No. 8 Season 2', 'Kaiju No. 8']);
      expect(candidates, ['Kaiju No. 8 Season 2', 'Kaiju No. 8']);
    });

    test('the preferred title\'s stripped form survives a long alias list', () {
      // MAL synonyms routinely exceed the cap. Emitting every raw alias first
      // would spend every slot without ever reaching the parent show.
      final candidates = titleMatchCandidates([
        'Mushoku Tensei: Jobless Reincarnation Season 2',
        'Mushoku Tensei II: Isekai Ittara Honki Dasu',
        'Mushoku Tensei 2',
        'MT2',
      ]);
      expect(candidates, ['Mushoku Tensei: Jobless Reincarnation Season 2', 'Mushoku Tensei: Jobless Reincarnation']);
    });
  });
}
