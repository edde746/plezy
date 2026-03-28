// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plex_role.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlexRole _$PlexRoleFromJson(Map<String, dynamic> json) => PlexRole(
  id: _flexibleInt(json['id']),
  filter: json['filter'] as String?,
  tag: json['tag'] as String,
  tagKey: json['tagKey'] as String?,
  role: json['role'] as String?,
  thumb: json['thumb'] as String?,
  count: _flexibleInt(json['count']),
);

Map<String, dynamic> _$PlexRoleToJson(PlexRole instance) => <String, dynamic>{
  'id': instance.id,
  'filter': instance.filter,
  'tag': instance.tag,
  'tagKey': instance.tagKey,
  'role': instance.role,
  'thumb': instance.thumb,
  'count': instance.count,
};
