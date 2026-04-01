import 'package:json_annotation/json_annotation.dart';

import '../utils/json_utils.dart';

part 'plex_role.g.dart';

@JsonSerializable()
class PlexRole {
  @JsonKey(fromJson: flexibleInt)
  final int? id;
  final String? filter;
  final String tag;
  final String? tagKey;
  final String? role;
  final String? thumb;
  @JsonKey(fromJson: flexibleInt)
  final int? count;

  PlexRole({this.id, this.filter, required this.tag, this.tagKey, this.role, this.thumb, this.count});

  factory PlexRole.fromJson(Map<String, dynamic> json) => _$PlexRoleFromJson(json);

  Map<String, dynamic> toJson() => _$PlexRoleToJson(this);
}
