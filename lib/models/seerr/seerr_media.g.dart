// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seerr_media.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SeerrMedia _$SeerrMediaFromJson(Map<String, dynamic> json) => SeerrMedia(
  id: (json['id'] as num).toInt(),
  mediaType: json['mediaType'] as String?,
  title: json['title'] as String?,
  name: json['name'] as String?,
  overview: json['overview'] as String?,
  posterPath: json['posterPath'] as String?,
  backdropPath: json['backdropPath'] as String?,
  releaseDate: json['releaseDate'] as String?,
  firstAirDate: json['firstAirDate'] as String?,
  voteAverage: (json['voteAverage'] as num?)?.toDouble(),
  voteCount: (json['voteCount'] as num?)?.toInt(),
  mediaInfo: json['mediaInfo'] == null
      ? null
      : SeerrMediaInfo.fromJson(json['mediaInfo'] as Map<String, dynamic>),
);

SeerrMediaInfo _$SeerrMediaInfoFromJson(Map<String, dynamic> json) =>
    SeerrMediaInfo(
      id: (json['id'] as num?)?.toInt(),
      tmdbId: (json['tmdbId'] as num?)?.toInt(),
      tvdbId: (json['tvdbId'] as num?)?.toInt(),
      status: json['status'] == null
          ? SeerrMediaStatus.unknown
          : SeerrMediaStatus.fromCode((json['status'] as num?)?.toInt()),
      status4k: json['status4k'] == null
          ? SeerrMediaStatus.unknown
          : SeerrMediaStatus.fromCode((json['status4k'] as num?)?.toInt()),
      seasons: (json['seasons'] as List<dynamic>?)
          ?.map((e) => SeerrSeasonInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      requests: (json['requests'] as List<dynamic>?)
          ?.map((e) => SeerrRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

SeerrSeasonInfo _$SeerrSeasonInfoFromJson(Map<String, dynamic> json) =>
    SeerrSeasonInfo(
      seasonNumber: (json['seasonNumber'] as num).toInt(),
      status: json['status'] == null
          ? SeerrMediaStatus.unknown
          : SeerrMediaStatus.fromCode((json['status'] as num?)?.toInt()),
      status4k: json['status4k'] == null
          ? SeerrMediaStatus.unknown
          : SeerrMediaStatus.fromCode((json['status4k'] as num?)?.toInt()),
    );
