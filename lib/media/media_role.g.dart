// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_role.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MediaRole _$MediaRoleFromJson(Map<String, dynamic> json) => MediaRole(
  id: json['id'] as String?,
  tag: stringOrEmpty(json['tag']),
  role: json['role'] as String?,
  thumbPath: json['thumbPath'] as String?,
);

Map<String, dynamic> _$MediaRoleToJson(MediaRole instance) => <String, dynamic>{
  'id': ?instance.id,
  'tag': instance.tag,
  'role': ?instance.role,
  'thumbPath': ?instance.thumbPath,
};
