// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'livetv_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LiveTvSession _$LiveTvSessionFromJson(Map<String, dynamic> json) => LiveTvSession(
  sessionID: readStringField(json, 'sessionID') as String? ?? '',
  dvrID: readStringField(json, 'dvrID') as String?,
  channelIdentifier: json['channelIdentifier'] as String?,
  channelCallSign: json['channelCallSign'] as String?,
  channelTitle: json['channelTitle'] as String?,
  activityUUID: json['activityUUID'] as String?,
  currentPosition: flexibleInt(json['currentPosition']),
  nextPosition: flexibleInt(json['nextPosition']),
  startedAt: flexibleInt(json['startedAt']),
  captureBuffer: _captureBufferFromRaw(json['CaptureBuffer']),
  grabOperation: _grabOperationFromRaw(json['MediaGrabOperation']),
  timeline: _firstMap(json['Timeline']),
  airingMetadataItem: _programFromRaw(json['AiringMetadataItem']),
  upNextMetadataItem: _programFromRaw(json['UpNextMetadataItem']),
);
