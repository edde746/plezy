import 'package:json_annotation/json_annotation.dart';

import '../../utils/json_utils.dart';
import 'simkl_ids.dart';

part 'simkl_all_items_entry.g.dart';

@JsonSerializable(createToJson: false)
class SimklAllItemsMedia {
  final String? title;
  @JsonKey(fromJson: flexibleInt)
  final int? year;
  final String? poster;
  final String? fanart;
  @JsonKey(fromJson: flexibleInt)
  final int? runtime;
  final String? overview;
  final List<String>? genres;
  final String? network;
  final String? status;
  final SimklIds ids;

  const SimklAllItemsMedia({
    this.title,
    this.year,
    this.poster,
    this.fanart,
    this.runtime,
    this.overview,
    this.genres,
    this.network,
    this.status,
    required this.ids,
  });

  factory SimklAllItemsMedia.fromJson(Map<String, dynamic> json) => _$SimklAllItemsMediaFromJson(json);
}

@JsonSerializable(createToJson: false)
class SimklAllItemsEntry {
  @JsonKey(name: 'added_to_watchlist_at')
  final String? addedAt;
  @JsonKey(name: 'user_rating', fromJson: flexibleDouble)
  final double? userRating;
  final SimklAllItemsMedia? show;
  final SimklAllItemsMedia? movie;
  @JsonKey(name: 'anime_type')
  final String? animeType;
  @JsonKey(name: 'total_episodes_count', fromJson: flexibleInt)
  final int? totalEpisodes;
  @JsonKey(name: 'not_aired_episodes_count', fromJson: flexibleInt)
  final int? notAiredEpisodes;

  const SimklAllItemsEntry({
    this.addedAt,
    this.userRating,
    this.show,
    this.movie,
    this.animeType,
    this.totalEpisodes,
    this.notAiredEpisodes,
  });

  SimklAllItemsMedia? get media => movie ?? show;

  factory SimklAllItemsEntry.fromJson(Map<String, dynamic> json) => _$SimklAllItemsEntryFromJson(json);
}

class SimklAllItems {
  final List<SimklAllItemsEntry> shows;
  final List<SimklAllItemsEntry> movies;
  final List<SimklAllItemsEntry> anime;

  const SimklAllItems({this.shows = const [], this.movies = const [], this.anime = const []});

  factory SimklAllItems.fromJson(Map<String, dynamic> json) =>
      SimklAllItems(shows: _entries(json['shows']), movies: _entries(json['movies']), anime: _entries(json['anime']));

  static List<SimklAllItemsEntry> _entries(Object? value) {
    if (value is! List) return const [];
    return [
      for (final entry in value)
        if (entry is Map<String, dynamic>) SimklAllItemsEntry.fromJson(entry),
    ];
  }
}
