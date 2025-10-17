// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plex_server_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlexServerInfo _$PlexServerInfoFromJson(Map<String, dynamic> json) =>
    PlexServerInfo(
      name: json['name'] as String,
      host: json['host'] as String?,
      port: (json['port'] as num?)?.toInt(),
      machineIdentifier: json['machineIdentifier'] as String?,
      version: json['version'] as String,
      owned: json['owned'] as bool?,
      https: json['https'] as bool?,
    );

Map<String, dynamic> _$PlexServerInfoToJson(PlexServerInfo instance) =>
    <String, dynamic>{
      'name': instance.name,
      'host': instance.host,
      'port': instance.port,
      'machineIdentifier': instance.machineIdentifier,
      'version': instance.version,
      'owned': instance.owned,
      'https': instance.https,
    };
