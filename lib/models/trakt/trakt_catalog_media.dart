import 'package:json_annotation/json_annotation.dart';

import 'trakt_ids.dart';
import 'trakt_images.dart';

part 'trakt_catalog_media.g.dart';

/// A show's recurring broadcast slot from Trakt's `airs` object.
class TraktAirs {
  final String? day;
  final String? time;
  final String? timezone;

  const TraktAirs({this.day, this.time, this.timezone});

  factory TraktAirs.fromJson(Map<String, dynamic> json) =>
      TraktAirs(day: json['day'] as String?, time: json['time'] as String?, timezone: json['timezone'] as String?);
}

/// Recommendation provenance attached to a personalised recommendation row.
class TraktRecommendationUser {
  final String? username;
  final String? name;
  final String? notes;

  const TraktRecommendationUser({this.username, this.name, this.notes});

  factory TraktRecommendationUser.fromJson(Map<String, dynamic> json) => TraktRecommendationUser(
    username: json['username'] as String?,
    name: json['name'] as String?,
    notes: json['notes'] as String?,
  );
}

/// A movie or show summary from Trakt's catalog endpoints (`extended=full`).
///
/// Trakt uses the same field names for movie and show objects. Whether an
/// instance is a movie or a show is known from the endpoint or wrapper key it
/// was parsed from (see [TraktCatalogEntry]).
@JsonSerializable(createToJson: false)
class TraktCatalogMedia {
  final String? title;
  final int? year;
  final TraktIds ids;
  final String? overview;
  final String? tagline;
  @JsonKey(name: 'original_title')
  final String? originalTitle;
  final String? released;
  @JsonKey(name: 'first_aired')
  final String? firstAired;

  /// Runtime in minutes.
  final int? runtime;

  /// Trakt community rating, 0–10.
  final double? rating;
  final int? votes;
  final List<String>? genres;
  final String? certification;
  final String? trailer;
  @JsonKey(name: 'comment_count')
  final int? commentCount;
  final String? language;
  final List<String>? languages;
  @JsonKey(name: 'available_translations')
  final List<String>? availableTranslations;
  final String? country;
  @JsonKey(name: 'favorited_by')
  final List<TraktRecommendationUser>? favoritedBy;
  @JsonKey(name: 'recommended_by')
  final List<TraktRecommendationUser>? recommendedBy;

  /// Shows: `returning series` / `continuing` / `in production` / `planned` /
  /// `upcoming` / `pilot` / `canceled` / `ended`. Movies: `released` /
  /// `in production` / `post production` / `planned` / `rumored` / `canceled`.
  final String? status;

  /// Shows only.
  final String? network;
  @JsonKey(name: 'aired_episodes')
  final int? airedEpisodes;
  final TraktAirs? airs;
  final TraktImages? images;

  const TraktCatalogMedia({
    this.title,
    this.year,
    required this.ids,
    this.overview,
    this.tagline,
    this.originalTitle,
    this.released,
    this.firstAired,
    this.runtime,
    this.rating,
    this.votes,
    this.genres,
    this.certification,
    this.trailer,
    this.commentCount,
    this.language,
    this.languages,
    this.availableTranslations,
    this.country,
    this.favoritedBy,
    this.recommendedBy,
    this.status,
    this.network,
    this.airedEpisodes,
    this.airs,
    this.images,
  });

  factory TraktCatalogMedia.fromJson(Map<String, dynamic> json) => _$TraktCatalogMediaFromJson(json);
}
