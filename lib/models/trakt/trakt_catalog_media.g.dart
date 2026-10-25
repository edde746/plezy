// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trakt_catalog_media.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TraktCatalogMedia _$TraktCatalogMediaFromJson(
  Map<String, dynamic> json,
) => TraktCatalogMedia(
  title: json['title'] as String?,
  year: (json['year'] as num?)?.toInt(),
  ids: TraktIds.fromJson(json['ids'] as Map<String, dynamic>),
  overview: json['overview'] as String?,
  tagline: json['tagline'] as String?,
  originalTitle: json['original_title'] as String?,
  released: json['released'] as String?,
  firstAired: json['first_aired'] as String?,
  runtime: (json['runtime'] as num?)?.toInt(),
  rating: (json['rating'] as num?)?.toDouble(),
  votes: (json['votes'] as num?)?.toInt(),
  genres: (json['genres'] as List<dynamic>?)?.map((e) => e as String).toList(),
  certification: json['certification'] as String?,
  trailer: json['trailer'] as String?,
  commentCount: (json['comment_count'] as num?)?.toInt(),
  language: json['language'] as String?,
  languages: (json['languages'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  availableTranslations: (json['available_translations'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  country: json['country'] as String?,
  favoritedBy: (json['favorited_by'] as List<dynamic>?)
      ?.map((e) => TraktRecommendationUser.fromJson(e as Map<String, dynamic>))
      .toList(),
  recommendedBy: (json['recommended_by'] as List<dynamic>?)
      ?.map((e) => TraktRecommendationUser.fromJson(e as Map<String, dynamic>))
      .toList(),
  status: json['status'] as String?,
  network: json['network'] as String?,
  airedEpisodes: (json['aired_episodes'] as num?)?.toInt(),
  airs: json['airs'] == null
      ? null
      : TraktAirs.fromJson(json['airs'] as Map<String, dynamic>),
  images: json['images'] == null
      ? null
      : TraktImages.fromJson(json['images'] as Map<String, dynamic>),
);
