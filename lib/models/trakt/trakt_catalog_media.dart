import 'package:json_annotation/json_annotation.dart';

import 'trakt_ids.dart';
import 'trakt_images.dart';

part 'trakt_catalog_media.g.dart';

/// A movie or show summary from Trakt's catalog endpoints (`extended=full`).
///
/// Trakt uses the same field names for movie and show objects; the fields
/// exclusive to one type (movie `released`, show `first_aired`, ...) are not
/// needed for the Explore surfaces, so a single class covers both. Whether an
/// instance is a movie or a show is known from the endpoint or wrapper key it
/// was parsed from (see [TraktCatalogEntry]).
@JsonSerializable(createToJson: false)
class TraktCatalogMedia {
  final String? title;
  final int? year;
  final TraktIds ids;
  final String? overview;

  /// Runtime in minutes.
  final int? runtime;

  /// Trakt community rating, 0–10.
  final double? rating;
  final int? votes;
  final List<String>? genres;
  final String? certification;
  final String? trailer;

  /// Shows: `returning series` / `continuing` / `in production` / `planned` /
  /// `upcoming` / `pilot` / `canceled` / `ended`. Movies: `released` /
  /// `in production` / `post production` / `planned` / `rumored` / `canceled`.
  final String? status;

  /// Shows only.
  final String? network;
  @JsonKey(name: 'aired_episodes')
  final int? airedEpisodes;
  final TraktImages? images;

  const TraktCatalogMedia({
    this.title,
    this.year,
    required this.ids,
    this.overview,
    this.runtime,
    this.rating,
    this.votes,
    this.genres,
    this.certification,
    this.trailer,
    this.status,
    this.network,
    this.airedEpisodes,
    this.images,
  });

  factory TraktCatalogMedia.fromJson(Map<String, dynamic> json) => _$TraktCatalogMediaFromJson(json);
}
