// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_version.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MediaVersion _$MediaVersionFromJson(Map<String, dynamic> json) => MediaVersion(
  id: _stringFromJson(json['id']),
  width: flexibleInt(json['width']),
  height: flexibleInt(json['height']),
  videoResolution: json['videoResolution'] as String?,
  videoCodec: json['videoCodec'] as String?,
  bitrate: flexibleInt(json['bitrate']),
  container: json['container'] as String?,
  parts: json['parts'] == null ? const [] : _partsFromJson(json['parts']),
  name: json['name'] as String?,
);

Map<String, dynamic> _$MediaVersionToJson(MediaVersion instance) => <String, dynamic>{
  'id': instance.id,
  'width': ?instance.width,
  'height': ?instance.height,
  'videoResolution': ?instance.videoResolution,
  'videoCodec': ?instance.videoCodec,
  'bitrate': ?instance.bitrate,
  'container': ?instance.container,
  'parts': _partsToJson(instance.parts),
  'name': ?instance.name,
};
