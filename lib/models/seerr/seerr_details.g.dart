// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seerr_details.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SeerrMovieDetails _$SeerrMovieDetailsFromJson(Map<String, dynamic> json) =>
    SeerrMovieDetails(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String?,
      overview: json['overview'] as String?,
      posterPath: json['posterPath'] as String?,
      backdropPath: json['backdropPath'] as String?,
      releaseDate: json['releaseDate'] as String?,
      runtime: (json['runtime'] as num?)?.toInt(),
      status: json['status'] as String?,
      voteAverage: (json['voteAverage'] as num?)?.toDouble(),
      voteCount: (json['voteCount'] as num?)?.toInt(),
      genres: (json['genres'] as List<dynamic>?)
          ?.map((e) => SeerrGenre.fromJson(e as Map<String, dynamic>))
          .toList(),
      credits: json['credits'] == null
          ? null
          : SeerrCredits.fromJson(json['credits'] as Map<String, dynamic>),
      externalIds: json['externalIds'] == null
          ? null
          : SeerrExternalIds.fromJson(
              json['externalIds'] as Map<String, dynamic>,
            ),
      mediaInfo: json['mediaInfo'] == null
          ? null
          : SeerrMediaInfo.fromJson(json['mediaInfo'] as Map<String, dynamic>),
    );

SeerrTvDetails _$SeerrTvDetailsFromJson(Map<String, dynamic> json) =>
    SeerrTvDetails(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String?,
      overview: json['overview'] as String?,
      posterPath: json['posterPath'] as String?,
      backdropPath: json['backdropPath'] as String?,
      firstAirDate: json['firstAirDate'] as String?,
      episodeRunTime: (json['episodeRunTime'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      status: json['status'] as String?,
      voteAverage: (json['voteAverage'] as num?)?.toDouble(),
      voteCount: (json['voteCount'] as num?)?.toInt(),
      genres: (json['genres'] as List<dynamic>?)
          ?.map((e) => SeerrGenre.fromJson(e as Map<String, dynamic>))
          .toList(),
      networks: (json['networks'] as List<dynamic>?)
          ?.map((e) => SeerrNetwork.fromJson(e as Map<String, dynamic>))
          .toList(),
      numberOfEpisodes: (json['numberOfEpisodes'] as num?)?.toInt(),
      numberOfSeasons: (json['numberOfSeasons'] as num?)?.toInt(),
      seasons: (json['seasons'] as List<dynamic>?)
          ?.map((e) => SeerrSeason.fromJson(e as Map<String, dynamic>))
          .toList(),
      credits: json['credits'] == null
          ? null
          : SeerrCredits.fromJson(json['credits'] as Map<String, dynamic>),
      externalIds: json['externalIds'] == null
          ? null
          : SeerrExternalIds.fromJson(
              json['externalIds'] as Map<String, dynamic>,
            ),
      mediaInfo: json['mediaInfo'] == null
          ? null
          : SeerrMediaInfo.fromJson(json['mediaInfo'] as Map<String, dynamic>),
    );

SeerrGenre _$SeerrGenreFromJson(Map<String, dynamic> json) =>
    SeerrGenre(name: json['name'] as String?);

SeerrNetwork _$SeerrNetworkFromJson(Map<String, dynamic> json) =>
    SeerrNetwork(name: json['name'] as String?);

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

SeerrExternalIds _$SeerrExternalIdsFromJson(Map<String, dynamic> json) =>
    SeerrExternalIds(
      imdbId: json['imdbId'] as String?,
      tvdbId: (json['tvdbId'] as num?)?.toInt(),
    );
