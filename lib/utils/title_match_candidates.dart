/// Season markers that begin a sequel suffix. Everything from the first match
/// to the end of the string is dropped, which collapses stacked suffixes
/// (`… Season 2 Part 2`, `… Season 3: The Culling Game Part 1`,
/// `… Season 2 -Arise from the Shadow-`) in one pass.
final List<RegExp> _seasonSuffixes = [
  RegExp(r'\s+season\s+\d+\b.*$', caseSensitive: false),
  RegExp(r'\s+\d+(?:st|nd|rd|th)\s+season\b.*$', caseSensitive: false),
  RegExp(r'\s+final\s+season\b.*$', caseSensitive: false),
  RegExp(r'\s+(?:part|cour|act)\.?\s*(?:\d+|i{1,3}v?|vi{0,3}|ix|x)\b.*$', caseSensitive: false),
  RegExp(r'\s+(?:ii|iii|iv|v|vi|vii|viii|ix|x)$', caseSensitive: false),
];

/// A bare trailing number usually marks a sequel (`Isekai Quartet 3`), so it is
/// stripped last — but only when the token before it does not expect a number.
/// `Kaiju No. 8` and `Vol. 3` are titles, not season two of anything.
final RegExp _bareTrailingNumber = RegExp(r'\s+\d+$');
final RegExp _numberedNoun = RegExp(r'\b(?:no|vol|pt|ep|episode|chapter)\.?\s+\d+$', caseSensitive: false);

/// Typographic variants media servers index differently from what catalog
/// providers emit. Plex tokenizes on these, Jellyfin substring-matches them,
/// and both miss `Journey’s` against a stored `Journey's`.
const Map<String, String> _punctuation = {
  '\u2019': "'", // right single quote
  '\u2018': "'",
  '\u201C': '"',
  '\u201D': '"',
  '\u2013': '-', // en dash
  '\u2014': '-', // em dash
  '\u30FB': ' ', // katakana middle dot
  '\uFF1A': ':',
  '\uFF01': '!',
  '\uFF1F': '?',
};

/// Drop the sequel suffix from [title], or return null when it has none.
String? stripSeasonSuffix(String title) {
  var out = title;
  for (final marker in _seasonSuffixes) {
    out = out.replaceFirst(marker, '');
  }
  if (!_numberedNoun.hasMatch(out)) {
    out = out.replaceFirst(_bareTrailingNumber, '');
  }
  out = out.trim();
  return out.isEmpty || out == title.trim() ? null : out;
}

String _normalize(String title) {
  var out = title;
  for (final entry in _punctuation.entries) {
    out = out.replaceAll(entry.key, entry.value);
  }
  return out.trim();
}

/// Ordered, deduplicated title candidates for a media-server reverse lookup.
///
/// Neither backend can filter by external id (Plex's `guid=` matches only the
/// primary `plex://` guid; Jellyfin dropped `anyProviderIdEquals`), so the
/// title is the only candidate filter available and a sequel entry's own
/// title — `You and I Are Polar Opposites Season 2` — never matches the parent
/// show. Each input contributes itself plus its season-stripped form; the
/// backend searches every candidate concurrently and verifies external ids,
/// so a candidate can only ever add genuine copies.
///
/// [limit] is the request budget per server per lookup. A title is a key into
/// the server's index, and a copy filed under a localized or romaji title is
/// reachable only through that title (#2098), so the budget buys title
/// *families*: 4 is the entry's own title and its first alternate, each with
/// its stripped form. Against a 267-show Plex library, the own family alone
/// matched 77 of 113 real sequel entries and six candidates reached 81; the
/// second family is not for hit rate but for the copies the first family
/// cannot name, and every request beyond it buys near nothing on the miss
/// path that dominates a discovery tab.
///
/// Each title is emitted immediately followed by its stripped form rather than
/// in two passes, so the cap can never spend every slot on unstripped titles
/// and never try the one candidate that actually reaches the parent show.
List<String> titleMatchCandidates(Iterable<String?> titles, {int limit = 4}) {
  final out = <String>[];
  final seen = <String>{};

  bool add(String? raw) {
    if (raw == null || out.length >= limit) return false;
    final title = _normalize(raw);
    if (title.isEmpty || !seen.add(title.toLowerCase())) return false;
    out.add(title);
    return true;
  }

  for (final title in titles) {
    if (out.length >= limit) break;
    final normalized = title == null ? null : _normalize(title);
    add(normalized);
    if (normalized != null) add(stripSeasonSuffix(normalized));
  }
  return out;
}
