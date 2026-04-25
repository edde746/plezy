// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plex_home.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlexHome _$PlexHomeFromJson(Map<String, dynamic> json) => PlexHome(
  id: (json['id'] as num?)?.toInt() ?? 0,
  name: json['name'] as String? ?? '',
  guestUserID: (json['guestUserID'] as num?)?.toInt(),
  guestUserUUID: json['guestUserUUID'] as String? ?? '',
  guestEnabled: json['guestEnabled'] as bool? ?? false,
  subscription: json['subscription'] as bool? ?? false,
  users:
      (json['users'] as List<dynamic>?)
          ?.map((e) => PlexHomeUser.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$PlexHomeToJson(PlexHome instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'guestUserID': instance.guestUserID,
  'guestUserUUID': instance.guestUserUUID,
  'guestEnabled': instance.guestEnabled,
  'subscription': instance.subscription,
  'users': instance.users,
};
