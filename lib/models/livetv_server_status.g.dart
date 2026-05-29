// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'livetv_server_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LiveTvServerStatus _$LiveTvServerStatusFromJson(Map<String, dynamic> json) => LiveTvServerStatus(
  liveTvCount: flexibleInt(json['livetv']),
  allowTuners: flexibleBoolNullable(json['allowTuners']),
  ownerFeatures: json['ownerFeatures'] as String?,
);
