// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seerr_details.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SeerrMovieDetails _$SeerrMovieDetailsFromJson(Map<String, dynamic> json) =>
    SeerrMovieDetails(
      credits: json['credits'] == null
          ? null
          : SeerrCredits.fromJson(json['credits'] as Map<String, dynamic>),
      mediaInfo: json['mediaInfo'] == null
          ? null
          : SeerrMediaInfo.fromJson(json['mediaInfo'] as Map<String, dynamic>),
    );

SeerrTvDetails _$SeerrTvDetailsFromJson(Map<String, dynamic> json) =>
    SeerrTvDetails(
      seasons: (json['seasons'] as List<dynamic>?)
          ?.map((e) => SeerrSeason.fromJson(e as Map<String, dynamic>))
          .toList(),
      credits: json['credits'] == null
          ? null
          : SeerrCredits.fromJson(json['credits'] as Map<String, dynamic>),
      mediaInfo: json['mediaInfo'] == null
          ? null
          : SeerrMediaInfo.fromJson(json['mediaInfo'] as Map<String, dynamic>),
    );

SeerrSeason _$SeerrSeasonFromJson(Map<String, dynamic> json) => SeerrSeason(
  seasonNumber: (json['seasonNumber'] as num).toInt(),
  name: json['name'] as String?,
  episodeCount: (json['episodeCount'] as num?)?.toInt(),
  airDate: json['airDate'] as String?,
);

SeerrCredits _$SeerrCreditsFromJson(Map<String, dynamic> json) => SeerrCredits(
  cast: (json['cast'] as List<dynamic>?)
      ?.map((e) => SeerrCastMember.fromJson(e as Map<String, dynamic>))
      .toList(),
);

SeerrCastMember _$SeerrCastMemberFromJson(Map<String, dynamic> json) =>
    SeerrCastMember(
      name: json['name'] as String?,
      character: json['character'] as String?,
      profilePath: json['profilePath'] as String?,
    );
