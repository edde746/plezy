// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plex_home.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlexHome _$PlexHomeFromJson(Map<String, dynamic> json) => PlexHome(
  id: flexibleIntOrZero(json['id']),
  name: readStringField(json, 'name') as String? ?? '',
  guestUserID: flexibleInt(json['guestUserID']),
  guestUserUUID: readStringField(json, 'guestUserUUID') as String? ?? '',
  guestEnabled: flexibleBool(json['guestEnabled']),
  subscription: flexibleBool(json['subscription']),
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
  'users': instance.users.map((e) => e.toJson()).toList(),
};
