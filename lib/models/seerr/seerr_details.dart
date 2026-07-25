import 'package:json_annotation/json_annotation.dart';

import 'seerr_media.dart';

part 'seerr_details.g.dart';

/// Full movie detail from `GET /movie/{tmdbId}` — the subset the catalog
/// surfaces need (credits, availability).
@JsonSerializable(createToJson: false)
class SeerrMovieDetails {
  final SeerrCredits? credits;
  final SeerrMediaInfo? mediaInfo;

  const SeerrMovieDetails({this.credits, this.mediaInfo});

  factory SeerrMovieDetails.fromJson(Map<String, dynamic> json) => _$SeerrMovieDetailsFromJson(json);
}

/// Full TV detail from `GET /tv/{tmdbId}`.
@JsonSerializable(createToJson: false)
class SeerrTvDetails {
  final List<SeerrSeason>? seasons;
  final SeerrCredits? credits;
  final SeerrMediaInfo? mediaInfo;

  const SeerrTvDetails({this.seasons, this.credits, this.mediaInfo});

  factory SeerrTvDetails.fromJson(Map<String, dynamic> json) => _$SeerrTvDetailsFromJson(json);
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
