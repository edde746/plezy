import 'package:json_annotation/json_annotation.dart';

import '../../utils/json_utils.dart';

part 'plex_subtitle_search_result.g.dart';

int _flexibleIntOrZero(Object? v) => flexibleInt(v) ?? 0;

@JsonSerializable()
class PlexSubtitleSearchResult {
  @JsonKey(fromJson: _flexibleIntOrZero)
  final int id;
  @JsonKey(readValue: readStringField, defaultValue: '')
  final String key;
  @JsonKey(readValue: readStringField)
  final String? codec;
  @JsonKey(readValue: readStringField)
  final String? language;
  @JsonKey(readValue: readStringField)
  final String? languageCode;
  @JsonKey(fromJson: flexibleDouble)
  final double? score;
  @JsonKey(readValue: readStringField)
  final String? providerTitle;
  @JsonKey(readValue: readStringField)
  final String? title;
  @JsonKey(readValue: readStringField)
  final String? displayTitle;
  @JsonKey(fromJson: flexibleBool)
  final bool hearingImpaired;
  @JsonKey(fromJson: flexibleBool)
  final bool perfectMatch;
  @JsonKey(fromJson: flexibleBool)
  final bool downloaded;
  @JsonKey(fromJson: flexibleBool)
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

  factory PlexSubtitleSearchResult.fromJson(Map<String, dynamic> json) => _$PlexSubtitleSearchResultFromJson(json);

  Map<String, dynamic> toJson() => _$PlexSubtitleSearchResultToJson(this);
}
