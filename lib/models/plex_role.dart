import 'package:json_annotation/json_annotation.dart';

part 'plex_role.g.dart';

int? _flexibleInt(Object? v) => switch (v) {
      num n => n.toInt(),
      String s => int.tryParse(s),
      _ => null,
    };

@JsonSerializable()
class PlexRole {
  @JsonKey(fromJson: _flexibleInt)
  final int? id;
  final String? filter;
  final String tag;
  final String? tagKey;
  final String? role;
  final String? thumb;
  @JsonKey(fromJson: _flexibleInt)
  final int? count;

  PlexRole({this.id, this.filter, required this.tag, this.tagKey, this.role, this.thumb, this.count});

  factory PlexRole.fromJson(Map<String, dynamic> json) => _$PlexRoleFromJson(json);

  Map<String, dynamic> toJson() => _$PlexRoleToJson(this);
}
