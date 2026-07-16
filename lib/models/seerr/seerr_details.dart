import 'package:json_annotation/json_annotation.dart';

import 'seerr_media.dart';

part 'seerr_details.g.dart';

/// Full movie detail from `GET /movie/{tmdbId}` — the subset the catalog
/// surfaces need (credits, external ids, availability, air status).
@JsonSerializable(createToJson: false)
class SeerrMovieDetails {
  final int id;
  final String? title;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;

  /// Minutes.
  final int? runtime;

  /// `Released` / `In Production` / `Post Production` / `Planned` /
  /// `Canceled` / `Rumored`.
  final String? status;
  final double? voteAverage;
  final int? voteCount;
  final List<SeerrGenre>? genres;
  final SeerrCredits? credits;
  final SeerrExternalIds? externalIds;
  final SeerrMediaInfo? mediaInfo;

  const SeerrMovieDetails({
    required this.id,
    this.title,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.releaseDate,
    this.runtime,
    this.status,
    this.voteAverage,
    this.voteCount,
    this.genres,
    this.credits,
    this.externalIds,
    this.mediaInfo,
  });

  factory SeerrMovieDetails.fromJson(Map<String, dynamic> json) => _$SeerrMovieDetailsFromJson(json);
}

/// Full TV detail from `GET /tv/{tmdbId}`.
@JsonSerializable(createToJson: false)
class SeerrTvDetails {
  final int id;
  final String? name;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final String? firstAirDate;
  final List<int>? episodeRunTime;

  /// `Returning Series` / `Ended` / `Canceled` / `In Production` /
  /// `Planned` / `Pilot`.
  final String? status;
  final double? voteAverage;
  final int? voteCount;
  final List<SeerrGenre>? genres;
  final List<SeerrNetwork>? networks;
  final int? numberOfEpisodes;
  final int? numberOfSeasons;
  final List<SeerrSeason>? seasons;
  final SeerrCredits? credits;
  final SeerrExternalIds? externalIds;
  final SeerrMediaInfo? mediaInfo;

  const SeerrTvDetails({
    required this.id,
    this.name,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.firstAirDate,
    this.episodeRunTime,
    this.status,
    this.voteAverage,
    this.voteCount,
    this.genres,
    this.networks,
    this.numberOfEpisodes,
    this.numberOfSeasons,
    this.seasons,
    this.credits,
    this.externalIds,
    this.mediaInfo,
  });

  factory SeerrTvDetails.fromJson(Map<String, dynamic> json) => _$SeerrTvDetailsFromJson(json);
}

@JsonSerializable(createToJson: false)
class SeerrGenre {
  final String? name;
  const SeerrGenre({this.name});
  factory SeerrGenre.fromJson(Map<String, dynamic> json) => _$SeerrGenreFromJson(json);
}

@JsonSerializable(createToJson: false)
class SeerrNetwork {
  final String? name;
  const SeerrNetwork({this.name});
  factory SeerrNetwork.fromJson(Map<String, dynamic> json) => _$SeerrNetworkFromJson(json);
}

/// One TMDB season entry (`TvDetails.seasons[]`). Season 0 is specials.
@JsonSerializable(createToJson: false)
class SeerrSeason {
  final int seasonNumber;
  final String? name;
  final int? episodeCount;
  final String? airDate;

  const SeerrSeason({required this.seasonNumber, this.name, this.episodeCount, this.airDate});

  factory SeerrSeason.fromJson(Map<String, dynamic> json) => _$SeerrSeasonFromJson(json);
}

@JsonSerializable(createToJson: false)
class SeerrCredits {
  final List<SeerrCastMember>? cast;
  const SeerrCredits({this.cast});
  factory SeerrCredits.fromJson(Map<String, dynamic> json) => _$SeerrCreditsFromJson(json);
}

@JsonSerializable(createToJson: false)
class SeerrCastMember {
  final String? name;
  final String? character;
  final String? profilePath;

  const SeerrCastMember({this.name, this.character, this.profilePath});

  factory SeerrCastMember.fromJson(Map<String, dynamic> json) => _$SeerrCastMemberFromJson(json);
}

@JsonSerializable(createToJson: false)
class SeerrExternalIds {
  final String? imdbId;
  final int? tvdbId;

  const SeerrExternalIds({this.imdbId, this.tvdbId});

  factory SeerrExternalIds.fromJson(Map<String, dynamic> json) => _$SeerrExternalIdsFromJson(json);
}
