import 'package:json_annotation/json_annotation.dart';

import 'seerr_media.dart';

part 'seerr_details.g.dart';

/// Full detail from `GET /movie/{tmdbId}` and `GET /tv/{tmdbId}` — the subset
/// the catalog surfaces need (credits, availability, seasons). `seasons` is
/// absent on movies.
@JsonSerializable(createToJson: false)
class SeerrDetails {
  final List<SeerrSeason>? seasons;
  final SeerrCredits? credits;
  final SeerrMediaInfo? mediaInfo;

  const SeerrDetails({this.seasons, this.credits, this.mediaInfo});

  factory SeerrDetails.fromJson(Map<String, dynamic> json) => _$SeerrDetailsFromJson(json);
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
