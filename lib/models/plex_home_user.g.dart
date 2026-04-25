// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plex_home_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlexHomeUser _$PlexHomeUserFromJson(Map<String, dynamic> json) => PlexHomeUser(
  id: (json['id'] as num?)?.toInt() ?? 0,
  uuid: json['uuid'] as String? ?? '',
  title: json['title'] as String? ?? 'Unknown',
  username: json['username'] as String?,
  email: json['email'] as String?,
  friendlyName: json['friendlyName'] as String?,
  thumb: json['thumb'] as String? ?? '',
  hasPassword: json['hasPassword'] as bool? ?? false,
  restricted: json['restricted'] as bool? ?? false,
  updatedAt: (json['updatedAt'] as num?)?.toInt(),
  admin: json['admin'] as bool? ?? false,
  guest: json['guest'] as bool? ?? false,
  protected: json['protected'] as bool? ?? false,
);

Map<String, dynamic> _$PlexHomeUserToJson(PlexHomeUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'uuid': instance.uuid,
      'title': instance.title,
      'username': instance.username,
      'email': instance.email,
      'friendlyName': instance.friendlyName,
      'thumb': instance.thumb,
      'hasPassword': instance.hasPassword,
      'restricted': instance.restricted,
      'updatedAt': instance.updatedAt,
      'admin': instance.admin,
      'guest': instance.guest,
      'protected': instance.protected,
    };
