class PlexSubtitleSearchResult {
  final int id;
  final String key;
  final String? codec;
  final String? language;
  final String? languageCode;
  final double? score;
  final String? providerTitle;
  final String? title;
  final String? displayTitle;
  final bool hearingImpaired;
  final bool perfectMatch;
  final bool downloaded;
  final bool forced;

  PlexSubtitleSearchResult({
    required this.id,
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

  factory PlexSubtitleSearchResult.fromJson(Map<String, dynamic> json) {
    return PlexSubtitleSearchResult(
      id: _parseInt(json['id']),
      key: json['key']?.toString() ?? '',
      codec: json['codec']?.toString(),
      language: json['language']?.toString(),
      languageCode: json['languageCode']?.toString(),
      score: _parseDouble(json['score']),
      providerTitle: json['providerTitle']?.toString(),
      title: json['title']?.toString(),
      displayTitle: json['displayTitle']?.toString(),
      hearingImpaired: json['hearingImpaired'] == 1 || json['hearingImpaired'] == true,
      perfectMatch: json['perfectMatch'] == 1 || json['perfectMatch'] == true,
      downloaded: json['downloaded'] == 1 || json['downloaded'] == true,
      forced: json['forced'] == 1 || json['forced'] == true,
    );
  }

  static int _parseInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static double? _parseDouble(dynamic v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}
