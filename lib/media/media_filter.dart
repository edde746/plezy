import 'package:json_annotation/json_annotation.dart';

part 'media_filter.g.dart';

@JsonSerializable()
class MediaFilter {
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

  MediaFilter({
    required this.filter,
    required this.filterType,
    required this.key,
    required this.title,
    required this.type,
  });

  factory MediaFilter.fromJson(Map<String, dynamic> json) => _$MediaFilterFromJson(json);

  Map<String, dynamic> toJson() => _$MediaFilterToJson(this);
}

@JsonSerializable(includeIfNull: false)
class MediaFilterValue {
  @JsonKey(defaultValue: '')
  final String key;
  @JsonKey(defaultValue: '')
  final String title;
  final String? type;

  MediaFilterValue({required this.key, required this.title, this.type});

  factory MediaFilterValue.fromJson(Map<String, dynamic> json) => _$MediaFilterValueFromJson(json);

  Map<String, dynamic> toJson() => _$MediaFilterValueToJson(this);
}
