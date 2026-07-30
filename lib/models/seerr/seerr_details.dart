import 'package:json_annotation/json_annotation.dart';

import '../../utils/json_utils.dart';

import 'seerr_media.dart';

part 'seerr_details.g.dart';

/// Full detail from `GET /movie/{tmdbId}` and `GET /tv/{tmdbId}`.
///
/// Both endpoints share the discovery fields below. Movie-only and TV-only
/// values remain nullable because Seerr deployments can omit TMDB data.
@JsonSerializable(createToJson: false)
class SeerrDetails {
  final int? id;
  final String? imdbId;
  final bool? adult;
  final String? title;
  final String? name;
  final String? originalTitle;
  final String? originalName;
  final String? originalLanguage;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final String? firstAirDate;
  final int? runtime;
  final List<int>? episodeRunTime;
  final int? budget;
  final int? revenue;
  final double? voteAverage;
  final int? voteCount;
  final double? popularity;
  final String? lastAirDate;
  final List<String>? languages;
  final List<SeerrSpokenLanguage>? spokenLanguages;
  final List<SeerrNamedValue>? genres;
  final List<SeerrNamedValue>? networks;
  final List<SeerrNamedValue>? productionCompanies;
  final List<SeerrProductionCountry>? productionCountries;
  final List<String>? originCountry;
  final List<SeerrNamedValue>? createdBy;
  final List<SeerrNamedValue>? keywords;
  final int? numberOfEpisodes;
  final String? status;
  final String? tagline;
  final SeerrReleaseInfo? releases;
  final SeerrContentRatingInfo? contentRatings;
  final SeerrExternalIds? externalIds;
  final List<SeerrRelatedVideo>? relatedVideos;
  final List<SeerrSeason>? seasons;
  final SeerrCredits? credits;
  final SeerrMediaInfo? mediaInfo;

  const SeerrDetails({
    this.id,
    this.imdbId,
    this.adult,
    this.title,
    this.name,
    this.originalTitle,
    this.originalName,
    this.originalLanguage,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.releaseDate,
    this.firstAirDate,
    this.runtime,
    this.episodeRunTime,
    this.budget,
    this.revenue,
    this.voteAverage,
    this.voteCount,
    this.popularity,
    this.lastAirDate,
    this.languages,
    this.spokenLanguages,
    this.genres,
    this.networks,
    this.productionCompanies,
    this.productionCountries,
    this.originCountry,
    this.createdBy,
    this.keywords,
    this.numberOfEpisodes,
    this.status,
    this.tagline,
    this.releases,
    this.contentRatings,
    this.externalIds,
    this.relatedVideos,
    this.seasons,
    this.credits,
    this.mediaInfo,
  });

  /// Localized title, falling back to the original when the requested
  /// language has no translation. TMDB answers a `language` query with an
  /// empty string rather than omitting the field, so `??` alone is not enough.
  String get displayTitle => firstNonBlank([title, name, originalTitle, originalName]) ?? '';

  String? get displayOriginalTitle => originalTitle ?? originalName;

  String? get date => releaseDate ?? firstAirDate;

  factory SeerrDetails.fromJson(Map<String, dynamic> json) => _$SeerrDetailsFromJson(json);
}

/// TMDB object carrying an integer id and a localized display name.
class SeerrNamedValue {
  final int? id;
  final String? name;

  const SeerrNamedValue({this.id, this.name});

  factory SeerrNamedValue.fromJson(Map<String, dynamic> json) =>
      SeerrNamedValue(id: (json['id'] as num?)?.toInt(), name: json['name'] as String?);
}

class SeerrProductionCountry {
  final String? countryCode;
  final String? name;

  const SeerrProductionCountry({this.countryCode, this.name});

  factory SeerrProductionCountry.fromJson(Map<String, dynamic> json) =>
      SeerrProductionCountry(countryCode: json['iso_3166_1'] as String?, name: json['name'] as String?);
}

class SeerrSpokenLanguage {
  final String? languageCode;
  final String? name;

  const SeerrSpokenLanguage({this.languageCode, this.name});

  factory SeerrSpokenLanguage.fromJson(Map<String, dynamic> json) =>
      SeerrSpokenLanguage(languageCode: json['iso_639_1'] as String?, name: json['name'] as String?);
}

class SeerrReleaseInfo {
  final List<SeerrReleaseCountry>? results;

  const SeerrReleaseInfo({this.results});

  factory SeerrReleaseInfo.fromJson(Map<String, dynamic> json) =>
      SeerrReleaseInfo(results: _decodeObjectList(json['results'], SeerrReleaseCountry.fromJson));
}

class SeerrReleaseCountry {
  final String? countryCode;
  final String? rating;
  final List<SeerrReleaseDate>? releaseDates;

  const SeerrReleaseCountry({this.countryCode, this.rating, this.releaseDates});

  factory SeerrReleaseCountry.fromJson(Map<String, dynamic> json) => SeerrReleaseCountry(
    countryCode: json['iso_3166_1'] as String?,
    rating: json['rating'] as String?,
    releaseDates: _decodeObjectList(json['release_dates'], SeerrReleaseDate.fromJson),
  );
}

class SeerrReleaseDate {
  final String? certification;

  const SeerrReleaseDate({this.certification});

  factory SeerrReleaseDate.fromJson(Map<String, dynamic> json) =>
      SeerrReleaseDate(certification: json['certification'] as String?);
}

class SeerrContentRatingInfo {
  final List<SeerrContentRating>? results;

  const SeerrContentRatingInfo({this.results});

  factory SeerrContentRatingInfo.fromJson(Map<String, dynamic> json) =>
      SeerrContentRatingInfo(results: _decodeObjectList(json['results'], SeerrContentRating.fromJson));
}

class SeerrContentRating {
  final String? countryCode;
  final String? rating;

  const SeerrContentRating({this.countryCode, this.rating});

  factory SeerrContentRating.fromJson(Map<String, dynamic> json) =>
      SeerrContentRating(countryCode: json['iso_3166_1'] as String?, rating: json['rating'] as String?);
}

class SeerrExternalIds {
  final String? imdbId;
  final int? tvdbId;

  const SeerrExternalIds({this.imdbId, this.tvdbId});

  factory SeerrExternalIds.fromJson(Map<String, dynamic> json) =>
      SeerrExternalIds(imdbId: json['imdbId'] as String?, tvdbId: (json['tvdbId'] as num?)?.toInt());
}

class SeerrRelatedVideo {
  final String? url;
  final String? key;
  final String? type;
  final String? site;

  const SeerrRelatedVideo({this.url, this.key, this.type, this.site});

  factory SeerrRelatedVideo.fromJson(Map<String, dynamic> json) => SeerrRelatedVideo(
    url: json['url'] as String?,
    key: json['key'] as String?,
    type: json['type'] as String?,
    site: json['site'] as String?,
  );
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
  final List<SeerrCrewMember>? crew;

  const SeerrCredits({this.cast, this.crew});

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

class SeerrCrewMember {
  final String? name;
  final String? job;
  final String? department;

  const SeerrCrewMember({this.name, this.job, this.department});

  factory SeerrCrewMember.fromJson(Map<String, dynamic> json) => SeerrCrewMember(
    name: json['name'] as String?,
    job: json['job'] as String?,
    department: json['department'] as String?,
  );
}

List<T>? _decodeObjectList<T>(Object? raw, T Function(Map<String, dynamic>) decode) {
  if (raw is! List) return null;
  return [
    for (final item in raw)
      if (item is Map<String, dynamic>) decode(item),
  ];
}
