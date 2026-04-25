import 'package:json_annotation/json_annotation.dart';

part 'plex_filter.g.dart';

@JsonSerializable()
class PlexFilter {
  @JsonKey(defaultValue: '')
  final String filter;
  @JsonKey(defaultValue: 'string')
  final String filterType;
  @JsonKey(defaultValue: '')
  final String key;
  @JsonKey(defaultValue: '')
  final String title;
  @JsonKey(defaultValue: 'filter')
  final String type;

  PlexFilter({
    required this.filter,
    required this.filterType,
    required this.key,
    required this.title,
    required this.type,
  });

  factory PlexFilter.fromJson(Map<String, dynamic> json) => _$PlexFilterFromJson(json);

  Map<String, dynamic> toJson() => _$PlexFilterToJson(this);
}

@JsonSerializable(includeIfNull: false)
class PlexFilterValue {
  @JsonKey(defaultValue: '')
  final String key;
  @JsonKey(defaultValue: '')
  final String title;
  final String? type;

  PlexFilterValue({required this.key, required this.title, this.type});

  factory PlexFilterValue.fromJson(Map<String, dynamic> json) => _$PlexFilterValueFromJson(json);

  Map<String, dynamic> toJson() => _$PlexFilterValueToJson(this);
}
