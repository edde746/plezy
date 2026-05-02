// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plex_mappers.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlexRoleDto _$PlexRoleDtoFromJson(Map<String, dynamic> json) => PlexRoleDto(
  id: flexibleInt(json['id']),
  filter: json['filter'] as String?,
  tag: json['tag'] as String,
  tagKey: json['tagKey'] as String?,
  role: json['role'] as String?,
  thumb: json['thumb'] as String?,
  count: flexibleInt(json['count']),
);

PlexLibraryDto _$PlexLibraryDtoFromJson(Map<String, dynamic> json) => PlexLibraryDto(
  key: readStringField(json, 'key') as String? ?? '',
  title: json['title'] as String? ?? '',
  type: json['type'] as String? ?? '',
  agent: json['agent'] as String?,
  scanner: json['scanner'] as String?,
  language: json['language'] as String?,
  uuid: json['uuid'] as String?,
  updatedAt: flexibleInt(json['updatedAt']),
  createdAt: flexibleInt(json['createdAt']),
  hidden: flexibleInt(json['hidden']),
);

PlexPlaylistDto _$PlexPlaylistDtoFromJson(Map<String, dynamic> json) => PlexPlaylistDto(
  ratingKey: readStringField(json, 'ratingKey') as String? ?? '',
  key: json['key'] as String? ?? '',
  type: json['type'] as String? ?? '',
  title: json['title'] as String? ?? '',
  summary: json['summary'] as String?,
  smart: json['smart'] as bool? ?? false,
  playlistType: json['playlistType'] as String? ?? '',
  duration: flexibleInt(json['duration']),
  leafCount: flexibleInt(json['leafCount']),
  composite: json['composite'] as String?,
  addedAt: flexibleInt(json['addedAt']),
  updatedAt: flexibleInt(json['updatedAt']),
  lastViewedAt: flexibleInt(json['lastViewedAt']),
  viewCount: flexibleInt(json['viewCount']),
  content: json['content'] as String?,
  guid: json['guid'] as String?,
  thumb: json['thumb'] as String?,
);
