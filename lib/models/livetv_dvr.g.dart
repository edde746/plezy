// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'livetv_dvr.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LiveTvDvr _$LiveTvDvrFromJson(Map<String, dynamic> json) => LiveTvDvr(
  key: json['key'] as String? ?? '',
  uuid: json['uuid'] as String? ?? '',
  make: json['make'] as String?,
  model: json['model'] as String?,
  modelNumber: json['modelNumber'] as String?,
  firmware: json['firmware'] as String?,
  tuners: flexibleInt(json['tuners']),
  lineup: json['lineup'] as String?,
  lineupTitle: json['lineupTitle'] as String?,
  lineupURL: json['lineupURL'] as String?,
  country: json['country'] as String?,
  language: json['language'] as String?,
  status: flexibleInt(json['status']),
  state: flexibleInt(json['state']),
  protocol: json['protocol'] as String?,
  sources: json['sources'] as String?,
  uri: json['uri'] as String?,
  lastSeenAt: flexibleInt(json['lastSeenAt']),
  channelMappings: json['ChannelMapping'] == null ? const [] : _parseChannelMappings(json['ChannelMapping']),
  settings: json['Setting'] == null ? const [] : _parseSettings(json['Setting']),
  devices: json['Device'] == null ? const [] : _parseRawMaps(json['Device']),
);

ChannelMapping _$ChannelMappingFromJson(Map<String, dynamic> json) => ChannelMapping(
  channelKey: json['channelKey'] as String?,
  deviceIdentifier: json['deviceIdentifier'] as String?,
  enabled: flexibleBool(json['enabled']),
  lineupIdentifier: json['lineupIdentifier'] as String?,
);
