/// One entry in the alpha-jump bar — a letter (or `#` bucket for items
/// starting with a digit / non-letter) plus the count of items beginning
/// with it.
///
/// Plex's `/library/sections/{id}/firstCharacter` endpoint returns these
/// natively (counts let the UI scroll to a cumulative offset). Jellyfin and
/// Emby have no equivalent endpoint, so `MediaBrowserAlphaBarStrategy`
/// synthesises a 27-letter alphabet with `size: 1` per entry — the bar
/// then acts as a name-prefix filter rather than a scroll affordance.
class LibraryFirstCharacter {
  final String key;
  final String title;
  final int size;

  const LibraryFirstCharacter({required this.key, required this.title, required this.size});
}

/// Which alpha bucket a string is filed under.
///
/// **Feed this the collation key, not the display title.** The two differ, and
/// the difference decides the answer: Music Assistant's `sort_name` for the
/// album displayed as `÷ (divide)` is the bare glyph `÷`, so `of(sortName)` is
/// [other] while `of(name)` is `D` — from *divide*. Every caller that has a
/// `sort_name`/`titleSort` must pass it; passing the display title asks a
/// different question and gets a different answer.
///
/// The rule is **the first letter or digit anywhere in the string**, not the
/// first character. That is not a simplification — it is what a Unicode
/// collation actually does, because punctuation and symbols carry no primary
/// weight. Verified against the live Music Assistant library:
///
/// | sort key | server puts it | bucket |
/// |---|---|---|
/// | `#10` | among the `10`s | `1` |
/// | `=1` | between `05 …` and `1` | `1` |
/// | `¡tré!` | 90% of the way through, under `t` | `T` |
/// | `"99" (kat krazy remix)` | among the `99`s | `9` |
/// | `!!!!!!!`, `@`, `...`, `+`, `-`, `÷` | the very front | [other] |
///
/// Bucketing on the *leading* character instead would claim `#10` lives in the
/// `#` bucket while the server has it sitting among the tens, which is exactly
/// the kind of lie that makes an alpha bar worse than no alpha bar.
///
/// [other] is the catch-all for a key with no letter and no digit at all —
/// `!!!!!!!`, `÷`, `🌈`. Those have no primary collation weight, which is why
/// every one of them lands at offset 0 of an ascending list *and* why they
/// arrive in no particular order relative to each other: their sort keys are all
/// equal, so the tie breaks on insertion order.
abstract final class LibraryAlphaBucket {
  /// The catch-all bucket, conventionally rendered `#`.
  ///
  /// It belongs **after** `Z`, not before `A`. This is the iOS
  /// `UILocalizedIndexedCollation` convention and it is the only defensible
  /// place for it: nobody opens a 33,000-album library looking for `!!!!!!!`
  /// first. Backends whose server supplies its own bucket offsets (Plex) keep
  /// the server's order — moving a bucket the offsets were computed for would
  /// desynchronise the bar from the list.
  static const String other = '#';

  /// The bucket [sortKey] belongs to: its first letter or digit, upper-cased,
  /// or [other] when it has neither.
  ///
  /// Digits are returned as themselves rather than folded into [other].
  /// A numeric title is a real, findable title — `1989`, `2112`, `808 State`,
  /// `9 Lazy 9` — and users look for it under its number, which is where every
  /// server's own collation already puts it. [other] is reserved for titles
  /// that have no findable form at all.
  static String of(String sortKey) {
    for (final rune in sortKey.runes) {
      final char = String.fromCharCode(rune);
      if (_isDigit(rune) || _isLetter(char)) return char.toUpperCase();
    }
    return other;
  }

  /// True when [sortKey] has no letter and no digit — the [other] bucket.
  static bool isOther(String sortKey) => of(sortKey) == other;

  /// ASCII digits only. A title written in Devanagari or Arabic-Indic numerals
  /// files under its script's letter bucket rather than under a digit the user
  /// cannot type, which is what [_letter] already does for it.
  static bool _isDigit(int rune) => rune >= 0x30 && rune <= 0x39;

  static bool _isLetter(String char) => _letter.hasMatch(char);

  /// `\p{L}` rather than a Latin range: the reference library holds CJK, Hangul
  /// and Cyrillic titles, and every one of them is a real title that must not
  /// fall into [other].
  static final RegExp _letter = RegExp(r'\p{L}', unicode: true);
}
