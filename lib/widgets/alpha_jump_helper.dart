import '../data/ducet_order.dart';
import '../models/plex_first_character.dart';

/// Shared letter-index mapping logic used by both [AlphaJumpBar] (desktop/tablet/TV)
/// and [AlphaScrollHandle] (phone).
///
/// Builds a dynamic letter list and cumulative index map from [PlexFirstCharacter]
/// data returned by the Plex API. Only letters that have items are included,
/// supporting non-Latin scripts (Korean, Japanese, Cyrillic, etc.).
///
/// The API's firstCharacter endpoint returns characters in Unicode codepoint
/// order, which doesn't match the content endpoint's ICU locale-aware sort.
/// We re-sort using ICU collation so cumulative indices are correct.
class AlphaJumpHelper {
  /// Dynamic letter list derived from the API's firstCharacter data,
  /// re-sorted to match ICU collation order.
  final List<String> letters;

  /// Maps each letter to its cumulative start index in the full item list.
  final Map<String, int> letterToIndex;

  /// Maps each letter to its item count.
  final Map<String, int> letterSizes;

  /// Total number of items across all letters.
  final int totalItemCount;

  AlphaJumpHelper._(this.letters, this.letterToIndex, this.letterSizes, this.totalItemCount);

  factory AlphaJumpHelper(List<PlexFirstCharacter> firstCharacters) {
    // Collect characters with their sizes.
    final entries = <({String letter, int size})>[];
    final letterSizes = <String, int>{};

    for (final fc in firstCharacters) {
      final letter = fc.title.toUpperCase();
      if (fc.size > 0) {
        entries.add((letter: letter, size: fc.size));
        letterSizes[letter] = fc.size;
      }
    }

    // Re-sort by DUCET collation to match the content endpoint's ICU sort order.
    entries.sort((a, b) => ducetCompare(a.letter, b.letter));

    // Build cumulative index map in the corrected order.
    final letters = <String>[];
    final letterToIndex = <String, int>{};
    int cumulative = 0;

    for (final e in entries) {
      letters.add(e.letter);
      letterToIndex[e.letter] = cumulative;
      cumulative += e.size;
    }

    return AlphaJumpHelper._(letters, letterToIndex, letterSizes, cumulative);
  }

  /// Returns at most [maxCount] letters, prioritizing those with the most
  /// items. The returned letters maintain their original order.
  List<String> displayLetters(int maxCount) {
    if (maxCount >= letters.length) return letters;
    if (maxCount <= 0) return const [];

    final indices = List.generate(letters.length, (i) => i);
    indices.sort((a, b) => (letterSizes[letters[b]] ?? 0).compareTo(letterSizes[letters[a]] ?? 0));
    final kept = indices.take(maxCount).toList()..sort();
    return [for (final i in kept) letters[i]];
  }

  /// Returns the letter that the given item index falls within.
  String currentLetter(int itemIndex) {
    if (letters.isEmpty) return '#';
    String current = letters.first;
    for (final letter in letters) {
      final startIndex = letterToIndex[letter];
      if (startIndex != null && startIndex <= itemIndex) {
        current = letter;
      }
    }
    return current;
  }

  /// Returns the cumulative start index for a letter, or null if not present.
  int? indexForLetter(String letter) => letterToIndex[letter];

  /// Returns the fractional position (0.0–1.0) for a letter, proportional to
  /// item count. Letters with more items occupy a larger segment.
  double fractionForLetter(String letter) {
    if (totalItemCount == 0) return 0.0;
    final index = letterToIndex[letter];
    if (index == null) return 0.0;
    return index / totalItemCount;
  }

  /// Returns the letter at a given fractional position (0.0–1.0), proportional
  /// to item count.
  String letterAtFraction(double fraction) {
    if (letters.isEmpty) return '#';
    if (totalItemCount == 0) return letters.first;
    final targetIndex = (fraction * totalItemCount).round().clamp(0, totalItemCount - 1);
    return currentLetter(targetIndex);
  }
}
