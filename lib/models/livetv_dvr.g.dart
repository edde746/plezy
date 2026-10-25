// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'livetv_dvr.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LiveTvDvr _$LiveTvDvrFromJson(Map<String, dynamic> json) => LiveTvDvr(
  key: json['key'] as String? ?? '',
  lineup: json['lineup'] as String?,
  lineupTitle: json['lineupTitle'] as String?,
  lineupURL: json['lineupURL'] as String?,
  channelMappings: json['ChannelMapping'] == null
      ? const []
      : _parseChannelMappings(json['ChannelMapping']),
);

ChannelMapping _$ChannelMappingFromJson(Map<String, dynamic> json) =>
    ChannelMapping(
      channelKey: json['channelKey'] as String?,
      enabled: flexibleBool(json['enabled']),
    );
