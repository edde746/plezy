import 'package:json_annotation/json_annotation.dart';

import '../../utils/json_utils.dart';
import 'simkl_ids.dart';
import 'simkl_rating.dart';

part 'simkl_trending_item.g.dart';

@JsonSerializable(createToJson: false)
class SimklTrendingItem {
  final String? title;
  final String? url;
  final String? poster;
  final String? fanart;
  @JsonKey(name: 'release_date')
  final String? releaseDate;
  final String? runtime;
  final String? status;
  final List<String>? genres;
  final String? trailer;
  final String? overview;
  final SimklRatings? ratings;
  @JsonKey(name: 'total_episodes', fromJson: flexibleInt)
  final int? totalEpisodes;
  final String? network;
  @JsonKey(name: 'anime_type')
  final String? animeType;
  final SimklIds ids;

  const SimklTrendingItem({
    this.title,
    this.url,
    this.poster,
    this.fanart,
    this.releaseDate,
    this.runtime,
    this.status,
    this.genres,
    this.trailer,
    this.overview,
    this.ratings,
    this.totalEpisodes,
    this.network,
    this.animeType,
    required this.ids,
  });

  int? get year {
    final parts = releaseDate?.split('/');
    if (parts == null || parts.length != 3) return null;
    return int.tryParse(parts[2]);
  }

  int? get runtimeMinutes {
    final value = runtime?.trim();
    if (value == null || value.isEmpty) return null;
    final match = RegExp(r'^(?:(\d+)\s*h)?(?:\s*(\d+)\s*m)?$', caseSensitive: false).firstMatch(value);
    if (match == null || (match.group(1) == null && match.group(2) == null)) return null;
    final hours = int.tryParse(match.group(1) ?? '') ?? 0;
    final minutes = int.tryParse(match.group(2) ?? '') ?? 0;
    final total = hours * 60 + minutes;
    return total > 0 ? total : null;
  }

  String? get trailerUrl => trailer == null || trailer!.isEmpty ? null : 'https://www.youtube.com/watch?v=$trailer';

  factory SimklTrendingItem.fromJson(Map<String, dynamic> json) => _$SimklTrendingItemFromJson(json);
}
