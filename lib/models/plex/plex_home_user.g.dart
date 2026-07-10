// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plex_home_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlexHomeUser _$PlexHomeUserFromJson(Map<String, dynamic> json) => PlexHomeUser(
  id: _intOr0(json['id']),
  uuid: readStringField(json, 'uuid') as String? ?? '',
  title: readStringField(json, 'title') as String? ?? 'Unknown',
  username: readStringField(json, 'username') as String?,
  email: readStringField(json, 'email') as String?,
  friendlyName: readStringField(json, 'friendlyName') as String?,
  thumb: readStringField(json, 'thumb') as String? ?? '',
  hasPassword: flexibleBool(json['hasPassword']),
  restricted: flexibleBool(json['restricted']),
  updatedAt: flexibleInt(json['updatedAt']),
  admin: flexibleBool(json['admin']),
  guest: flexibleBool(json['guest']),
  protected: flexibleBool(json['protected']),
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
