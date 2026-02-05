import '../models/plex_first_character.dart';

/// Shared letter-index mapping logic used by both [AlphaJumpBar] (desktop/tablet/TV)
/// and [AlphaScrollHandle] (phone).
///
/// Builds a cumulative index map from [PlexFirstCharacter] data and provides
/// fraction-based mapping for proportional scroll handle positioning.
class AlphaJumpHelper {
  static const List<String> allLetters = [
    '#',
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
  ];

  /// Maps each letter to its cumulative start index in the full item list.
  final Map<String, int> letterToIndex;

  /// Letters that have at least one item in the data.
  final Set<String> activeLetters;

  /// Total number of items across all letters.
  final int totalItemCount;

  AlphaJumpHelper._(this.letterToIndex, this.activeLetters, this.totalItemCount);

  factory AlphaJumpHelper(List<PlexFirstCharacter> firstCharacters) {
    // Build a lookup from the API data. Note: the firstCharacters API may
    // count by display title (e.g. "The Simpsons" → T) rather than titleSort
    // ("Simpsons" → S), so cumulative indices are approximate. The browse tab
    // corrects for this when jumping by searching loaded items' titleSort.
    final sizeByLetter = <String, int>{};
    for (final fc in firstCharacters) {
      sizeByLetter[fc.title.toUpperCase()] = fc.size;
    }

    // Compute cumulative indices in allLetters order (#, A, B, …, Z).
    final letterToIndex = <String, int>{};
    final activeLetters = <String>{};
    int cumulative = 0;

    for (final letter in allLetters) {
      final size = sizeByLetter[letter];
      if (size != null && size > 0) {
        activeLetters.add(letter);
        letterToIndex[letter] = cumulative;
        cumulative += size;
      }
    }

    return AlphaJumpHelper._(letterToIndex, activeLetters, cumulative);
  }

  /// Returns the letter that the given item index falls within.
  String currentLetter(int itemIndex) {
    String current = allLetters.first;
    for (final letter in allLetters) {
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
    if (totalItemCount == 0) return allLetters.first;
    final targetIndex = (fraction * totalItemCount).round().clamp(0, totalItemCount - 1);
    return currentLetter(targetIndex);
  }
}
