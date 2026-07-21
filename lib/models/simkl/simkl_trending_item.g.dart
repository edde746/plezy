// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'simkl_trending_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SimklTrendingItem _$SimklTrendingItemFromJson(Map<String, dynamic> json) =>
    SimklTrendingItem(
      title: json['title'] as String?,
      url: json['url'] as String?,
      poster: json['poster'] as String?,
      fanart: json['fanart'] as String?,
      releaseDate: json['release_date'] as String?,
      runtime: json['runtime'] as String?,
      status: json['status'] as String?,
      genres: (json['genres'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      trailer: json['trailer'] as String?,
      overview: json['overview'] as String?,
      ratings: json['ratings'] == null
          ? null
          : SimklRatings.fromJson(json['ratings'] as Map<String, dynamic>),
      totalEpisodes: flexibleInt(json['total_episodes']),
      network: json['network'] as String?,
      animeType: json['anime_type'] as String?,
      ids: SimklIds.fromJson(json['ids'] as Map<String, dynamic>),
    );
