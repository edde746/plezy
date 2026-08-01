// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_part.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MediaPart _$MediaPartFromJson(Map<String, dynamic> json) => MediaPart(
  id: stringOrEmpty(json['id']),
  streamPath: json['streamPath'] as String?,
  file: json['file'] as String?,
  sizeBytes: flexibleInt(json['sizeBytes']),
  container: json['container'] as String?,
  durationMs: flexibleInt(json['durationMs']),
  accessible: json['accessible'] as bool?,
  exists: json['exists'] as bool?,
);

Map<String, dynamic> _$MediaPartToJson(MediaPart instance) => <String, dynamic>{
  'id': instance.id,
  'streamPath': ?instance.streamPath,
  'file': ?instance.file,
  'sizeBytes': ?instance.sizeBytes,
  'container': ?instance.container,
  'durationMs': ?instance.durationMs,
  'accessible': ?instance.accessible,
  'exists': ?instance.exists,
};
