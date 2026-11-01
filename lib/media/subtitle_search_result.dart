/// One row of a server's external subtitle search, whichever server answered:
/// each client maps its own wire format onto it.
class SubtitleSearchResult {
  /// What the server needs back to download this row.
  final String key;
  final String? codec;
  final String? language;

  /// The language to download it in; clients fill it from the search when
  /// the server leaves it out.
  final String? languageCode;
  final double? score;
  final String? providerTitle;
  final String? title;
  final String? displayTitle;
  final bool hearingImpaired;
  final bool perfectMatch;
  final bool downloaded;
  final bool forced;

  const SubtitleSearchResult({
    required this.key,
    this.codec,
    this.language,
    this.languageCode,
    this.score,
    this.providerTitle,
    this.title,
    this.displayTitle,
    this.hearingImpaired = false,
    this.perfectMatch = false,
    this.downloaded = false,
    this.forced = false,
  });
}
