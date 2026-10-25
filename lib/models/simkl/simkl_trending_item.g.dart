// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'simkl_trending_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SimklTrendingItem _$SimklTrendingItemFromJson(Map<String, dynamic> json) =>
    SimklTrendingItem(
      title: json['title'] as String?,
      titleRomaji: json['title_romaji'] as String?,
      alternateTitles: simklTitleNames(json['alt_titles']),
      url: json['url'] as String?,
      poster: json['poster'] as String?,
      fanart: json['fanart'] as String?,
      releaseDate: json['release_date'] as String?,
      rank: flexibleInt(json['rank']),
      dropRate: json['drop_rate'] as String?,
      watched: flexibleInt(json['watched']),
      planToWatch: flexibleInt(json['plan_to_watch']),
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
      country: json['country'] as String?,
      originalLanguage: json['original_language'] as String?,
      totalEpisodes: flexibleInt(json['total_episodes']),
      network: json['network'] as String?,
      animeType: json['anime_type'] as String?,
      dvdDate: json['dvd_date'] as String?,
      theater: json['theater'] as String?,
      ids: SimklIds.fromJson(json['ids'] as Map<String, dynamic>),
    );
