// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plex_activity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlexActivity _$PlexActivityFromJson(Map<String, dynamic> json) => PlexActivity(
  uuid: stringOrEmpty(json['uuid']),
  type: stringOrEmpty(json['type']),
  title: stringOrEmpty(json['title']),
  subtitle: readStringField(json, 'subtitle') as String?,
  progress: flexibleIntOrZero(json['progress']),
  cancellable: flexibleBool(json['cancellable']),
);
