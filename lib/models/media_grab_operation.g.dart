// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_grab_operation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MediaGrabOperation _$MediaGrabOperationFromJson(Map<String, dynamic> json) => MediaGrabOperation(
  mediaSubscriptionID: flexibleInt(json['mediaSubscriptionID']),
  mediaIndex: flexibleInt(json['mediaIndex']),
  id: json['id'] as String? ?? '',
  key: json['key'] as String?,
  grabberIdentifier: json['grabberIdentifier'] as String?,
  grabberProtocol: json['grabberProtocol'] as String?,
  percent: flexibleDouble(json['percent']),
  currentSize: flexibleInt(json['currentSize']),
  status: json['status'] as String?,
  provider: json['provider'] as String?,
  rolling: flexibleBoolNullable(json['rolling']),
  error: json['error'] as String?,
  linkedKey: json['linkedKey'] as String?,
  metadata: _metadataFromJson(json['Metadata']),
);
