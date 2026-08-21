// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plex_home.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlexHome _$PlexHomeFromJson(Map<String, dynamic> json) => PlexHome(
  id: flexibleIntOrZero(json['id']),
  users:
      (json['users'] as List<dynamic>?)
          ?.map((e) => PlexHomeUser.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$PlexHomeToJson(PlexHome instance) => <String, dynamic>{
  'id': instance.id,
  'users': instance.users.map((e) => e.toJson()).toList(),
};
