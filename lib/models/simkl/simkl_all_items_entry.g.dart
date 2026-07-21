// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'simkl_all_items_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SimklAllItemsMedia _$SimklAllItemsMediaFromJson(Map<String, dynamic> json) =>
    SimklAllItemsMedia(
      title: json['title'] as String?,
      year: flexibleInt(json['year']),
      poster: json['poster'] as String?,
      fanart: json['fanart'] as String?,
      runtime: flexibleInt(json['runtime']),
      overview: json['overview'] as String?,
      genres: (json['genres'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      network: json['network'] as String?,
      status: json['status'] as String?,
      ids: SimklIds.fromJson(json['ids'] as Map<String, dynamic>),
    );

SimklAllItemsEntry _$SimklAllItemsEntryFromJson(Map<String, dynamic> json) =>
    SimklAllItemsEntry(
      status: json['status'] as String?,
      show: json['show'] == null
          ? null
          : SimklAllItemsMedia.fromJson(json['show'] as Map<String, dynamic>),
      movie: json['movie'] == null
          ? null
          : SimklAllItemsMedia.fromJson(json['movie'] as Map<String, dynamic>),
      animeType: json['anime_type'] as String?,
      totalEpisodes: flexibleInt(json['total_episodes_count']),
    );
