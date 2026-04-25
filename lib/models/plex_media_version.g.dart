// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plex_media_version.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlexMediaVersion _$PlexMediaVersionFromJson(Map<String, dynamic> json) =>
    PlexMediaVersion(
      id: _flexibleIntOrZero(json['id']),
      videoResolution: readStringField(json, 'videoResolution') as String?,
      videoCodec: readStringField(json, 'videoCodec') as String?,
      bitrate: flexibleInt(json['bitrate']),
      width: flexibleInt(json['width']),
      height: flexibleInt(json['height']),
      container: readStringField(json, 'container') as String?,
      partKey: _readPartKey(json, 'partKey') as String,
    );
