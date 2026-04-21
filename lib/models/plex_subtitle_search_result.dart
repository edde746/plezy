import '../utils/json_utils.dart';

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
      id: flexibleInt(json['id']) ?? 0,
      key: json['key']?.toString() ?? '',
      codec: json['codec']?.toString(),
      language: json['language']?.toString(),
      languageCode: json['languageCode']?.toString(),
      score: flexibleDouble(json['score']),
      providerTitle: json['providerTitle']?.toString(),
      title: json['title']?.toString(),
      displayTitle: json['displayTitle']?.toString(),
      hearingImpaired: flexibleBool(json['hearingImpaired']),
      perfectMatch: flexibleBool(json['perfectMatch']),
      downloaded: flexibleBool(json['downloaded']),
      forced: flexibleBool(json['forced']),
    );
  }
}
