// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plex_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlexMetadata _$PlexMetadataFromJson(Map<String, dynamic> json) => PlexMetadata(
  ratingKey: json['ratingKey'] as String,
  key: json['key'] as String,
  guid: json['guid'] as String?,
  studio: json['studio'] as String?,
  type: json['type'] as String,
  title: json['title'] as String,
  contentRating: json['contentRating'] as String?,
  summary: json['summary'] as String?,
  rating: (json['rating'] as num?)?.toDouble(),
  audienceRating: (json['audienceRating'] as num?)?.toDouble(),
  year: (json['year'] as num?)?.toInt(),
  thumb: json['thumb'] as String?,
  art: json['art'] as String?,
  duration: (json['duration'] as num?)?.toInt(),
  addedAt: (json['addedAt'] as num?)?.toInt(),
  updatedAt: (json['updatedAt'] as num?)?.toInt(),
  grandparentTitle: json['grandparentTitle'] as String?,
  grandparentThumb: json['grandparentThumb'] as String?,
  grandparentArt: json['grandparentArt'] as String?,
  grandparentRatingKey: json['grandparentRatingKey'] as String?,
  parentTitle: json['parentTitle'] as String?,
  parentThumb: json['parentThumb'] as String?,
  parentRatingKey: json['parentRatingKey'] as String?,
  parentIndex: (json['parentIndex'] as num?)?.toInt(),
  index: (json['index'] as num?)?.toInt(),
  grandparentTheme: json['grandparentTheme'] as String?,
  viewOffset: (json['viewOffset'] as num?)?.toInt(),
  viewCount: (json['viewCount'] as num?)?.toInt(),
  leafCount: (json['leafCount'] as num?)?.toInt(),
  viewedLeafCount: (json['viewedLeafCount'] as num?)?.toInt(),
  role: (json['Role'] as List<dynamic>?)
      ?.map((e) => PlexRole.fromJson(e as Map<String, dynamic>))
      .toList(),
  audioLanguage: json['audioLanguage'] as String?,
  subtitleLanguage: json['subtitleLanguage'] as String?,
  playlistItemID: (json['playlistItemID'] as num?)?.toInt(),
);

Map<String, dynamic> _$PlexMetadataToJson(PlexMetadata instance) =>
    <String, dynamic>{
      'ratingKey': instance.ratingKey,
      'key': instance.key,
      'guid': instance.guid,
      'studio': instance.studio,
      'type': instance.type,
      'title': instance.title,
      'contentRating': instance.contentRating,
      'summary': instance.summary,
      'rating': instance.rating,
      'audienceRating': instance.audienceRating,
      'year': instance.year,
      'thumb': instance.thumb,
      'art': instance.art,
      'duration': instance.duration,
      'addedAt': instance.addedAt,
      'updatedAt': instance.updatedAt,
      'grandparentTitle': instance.grandparentTitle,
      'grandparentThumb': instance.grandparentThumb,
      'grandparentArt': instance.grandparentArt,
      'grandparentRatingKey': instance.grandparentRatingKey,
      'parentTitle': instance.parentTitle,
      'parentThumb': instance.parentThumb,
      'parentRatingKey': instance.parentRatingKey,
      'parentIndex': instance.parentIndex,
      'index': instance.index,
      'grandparentTheme': instance.grandparentTheme,
      'viewOffset': instance.viewOffset,
      'viewCount': instance.viewCount,
      'leafCount': instance.leafCount,
      'viewedLeafCount': instance.viewedLeafCount,
      'Role': instance.role,
      'audioLanguage': instance.audioLanguage,
      'subtitleLanguage': instance.subtitleLanguage,
      'playlistItemID': instance.playlistItemID,
    };
