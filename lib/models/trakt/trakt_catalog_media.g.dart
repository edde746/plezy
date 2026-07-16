// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trakt_catalog_media.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TraktCatalogMedia _$TraktCatalogMediaFromJson(Map<String, dynamic> json) =>
    TraktCatalogMedia(
      title: json['title'] as String?,
      year: (json['year'] as num?)?.toInt(),
      ids: TraktIds.fromJson(json['ids'] as Map<String, dynamic>),
      overview: json['overview'] as String?,
      runtime: (json['runtime'] as num?)?.toInt(),
      rating: (json['rating'] as num?)?.toDouble(),
      votes: (json['votes'] as num?)?.toInt(),
      genres: (json['genres'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      certification: json['certification'] as String?,
      trailer: json['trailer'] as String?,
      status: json['status'] as String?,
      network: json['network'] as String?,
      airedEpisodes: (json['aired_episodes'] as num?)?.toInt(),
      images: json['images'] == null
          ? null
          : TraktImages.fromJson(json['images'] as Map<String, dynamic>),
    );
