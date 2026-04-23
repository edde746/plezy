import '../utils/json_utils.dart';

class PlexMatchResult {
  final String guid;
  final String name;
  final int? year;
  final int? score;
  final String? thumb;
  final String? summary;
  final String? type;
  final bool matched;

  PlexMatchResult({
    required this.guid,
    required this.name,
    this.year,
    this.score,
    this.thumb,
    this.summary,
    this.type,
    this.matched = false,
  });

  factory PlexMatchResult.fromJson(Map<String, dynamic> json) {
    return PlexMatchResult(
      guid: json['guid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      year: flexibleInt(json['year']),
      score: flexibleInt(json['score']),
      thumb: json['thumb']?.toString(),
      summary: json['summary']?.toString(),
      type: json['type']?.toString(),
      matched: flexibleBool(json['matched']),
    );
  }
}
