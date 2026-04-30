import 'package:json_annotation/json_annotation.dart';

import '../../utils/json_utils.dart';

part 'plex_match_result.g.dart';

@JsonSerializable()
class PlexMatchResult {
  @JsonKey(readValue: readStringField, defaultValue: '')
  final String guid;
  @JsonKey(readValue: readStringField, defaultValue: '')
  final String name;
  @JsonKey(fromJson: flexibleInt)
  final int? year;
  @JsonKey(fromJson: flexibleInt)
  final int? score;
  @JsonKey(readValue: readStringField)
  final String? thumb;
  @JsonKey(readValue: readStringField)
  final String? summary;
  @JsonKey(readValue: readStringField)
  final String? type;
  @JsonKey(fromJson: flexibleBool)
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

  factory PlexMatchResult.fromJson(Map<String, dynamic> json) => _$PlexMatchResultFromJson(json);

  Map<String, dynamic> toJson() => _$PlexMatchResultToJson(this);
}
