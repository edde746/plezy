import 'package:json_annotation/json_annotation.dart';

import '../utils/json_utils.dart';

part 'media_role.g.dart';

/// A cast or crew member attached to a media item.
@JsonSerializable(includeIfNull: false)
class MediaRole {
  final String? id;
  @JsonKey(fromJson: stringOrEmpty)
  final String tag;
  final String? role;
  final String? thumbPath;

  const MediaRole({this.id, required this.tag, this.role, this.thumbPath});

  factory MediaRole.fromJson(Map<String, dynamic> json) => _$MediaRoleFromJson(json);

  Map<String, dynamic> toJson() => _$MediaRoleToJson(this);
}
