// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plex_playlist.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlexPlaylist _$PlexPlaylistFromJson(Map<String, dynamic> json) => PlexPlaylist(
  ratingKey: json['ratingKey'] as String,
  key: json['key'] as String,
  type: json['type'] as String,
  title: json['title'] as String,
  summary: json['summary'] as String?,
  smart: json['smart'] as bool,
  playlistType: json['playlistType'] as String,
  duration: (json['duration'] as num?)?.toInt(),
  leafCount: (json['leafCount'] as num?)?.toInt(),
  composite: json['composite'] as String?,
  addedAt: (json['addedAt'] as num?)?.toInt(),
  updatedAt: (json['updatedAt'] as num?)?.toInt(),
  lastViewedAt: (json['lastViewedAt'] as num?)?.toInt(),
  viewCount: (json['viewCount'] as num?)?.toInt(),
  content: json['content'] as String?,
  guid: json['guid'] as String?,
  thumb: json['thumb'] as String?,
);

Map<String, dynamic> _$PlexPlaylistToJson(PlexPlaylist instance) =>
    <String, dynamic>{
      'ratingKey': instance.ratingKey,
      'key': instance.key,
      'type': instance.type,
      'title': instance.title,
      'summary': instance.summary,
      'smart': instance.smart,
      'playlistType': instance.playlistType,
      'duration': instance.duration,
      'leafCount': instance.leafCount,
      'composite': instance.composite,
      'addedAt': instance.addedAt,
      'updatedAt': instance.updatedAt,
      'lastViewedAt': instance.lastViewedAt,
      'viewCount': instance.viewCount,
      'content': instance.content,
      'guid': instance.guid,
      'thumb': instance.thumb,
    };
