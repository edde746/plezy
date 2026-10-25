// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seerr_details.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SeerrDetails _$SeerrDetailsFromJson(Map<String, dynamic> json) => SeerrDetails(
  id: (json['id'] as num?)?.toInt(),
  imdbId: json['imdbId'] as String?,
  adult: json['adult'] as bool?,
  title: json['title'] as String?,
  name: json['name'] as String?,
  originalTitle: json['originalTitle'] as String?,
  originalName: json['originalName'] as String?,
  originalLanguage: json['originalLanguage'] as String?,
  overview: json['overview'] as String?,
  posterPath: json['posterPath'] as String?,
  backdropPath: json['backdropPath'] as String?,
  releaseDate: json['releaseDate'] as String?,
  firstAirDate: json['firstAirDate'] as String?,
  runtime: (json['runtime'] as num?)?.toInt(),
  episodeRunTime: (json['episodeRunTime'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  budget: (json['budget'] as num?)?.toInt(),
  revenue: (json['revenue'] as num?)?.toInt(),
  voteAverage: (json['voteAverage'] as num?)?.toDouble(),
  voteCount: (json['voteCount'] as num?)?.toInt(),
  popularity: (json['popularity'] as num?)?.toDouble(),
  lastAirDate: json['lastAirDate'] as String?,
  languages: (json['languages'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  spokenLanguages: (json['spokenLanguages'] as List<dynamic>?)
      ?.map((e) => SeerrSpokenLanguage.fromJson(e as Map<String, dynamic>))
      .toList(),
  genres: (json['genres'] as List<dynamic>?)
      ?.map((e) => SeerrNamedValue.fromJson(e as Map<String, dynamic>))
      .toList(),
  networks: (json['networks'] as List<dynamic>?)
      ?.map((e) => SeerrNamedValue.fromJson(e as Map<String, dynamic>))
      .toList(),
  productionCompanies: (json['productionCompanies'] as List<dynamic>?)
      ?.map((e) => SeerrNamedValue.fromJson(e as Map<String, dynamic>))
      .toList(),
  productionCountries: (json['productionCountries'] as List<dynamic>?)
      ?.map((e) => SeerrProductionCountry.fromJson(e as Map<String, dynamic>))
      .toList(),
  originCountry: (json['originCountry'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  createdBy: (json['createdBy'] as List<dynamic>?)
      ?.map((e) => SeerrNamedValue.fromJson(e as Map<String, dynamic>))
      .toList(),
  keywords: (json['keywords'] as List<dynamic>?)
      ?.map((e) => SeerrNamedValue.fromJson(e as Map<String, dynamic>))
      .toList(),
  numberOfEpisodes: (json['numberOfEpisodes'] as num?)?.toInt(),
  status: json['status'] as String?,
  tagline: json['tagline'] as String?,
  releases: json['releases'] == null
      ? null
      : SeerrReleaseInfo.fromJson(json['releases'] as Map<String, dynamic>),
  contentRatings: json['contentRatings'] == null
      ? null
      : SeerrContentRatingInfo.fromJson(
          json['contentRatings'] as Map<String, dynamic>,
        ),
  externalIds: json['externalIds'] == null
      ? null
      : SeerrExternalIds.fromJson(json['externalIds'] as Map<String, dynamic>),
  relatedVideos: (json['relatedVideos'] as List<dynamic>?)
      ?.map((e) => SeerrRelatedVideo.fromJson(e as Map<String, dynamic>))
      .toList(),
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
  crew: (json['crew'] as List<dynamic>?)
      ?.map((e) => SeerrCrewMember.fromJson(e as Map<String, dynamic>))
      .toList(),
);

SeerrCastMember _$SeerrCastMemberFromJson(Map<String, dynamic> json) =>
    SeerrCastMember(
      name: json['name'] as String?,
      character: json['character'] as String?,
      profilePath: json['profilePath'] as String?,
    );
