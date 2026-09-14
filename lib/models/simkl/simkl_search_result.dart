import 'package:json_annotation/json_annotation.dart';

import '../../utils/json_utils.dart';
import 'simkl_ids.dart';
import 'simkl_rating.dart';

part 'simkl_search_result.g.dart';

@JsonSerializable(createToJson: false)
class SimklSearchResult {
  final String? title;
  @JsonKey(name: 'title_en')
  final String? titleEn;
  @JsonKey(name: 'title_romaji')
  final String? titleRomaji;
  @JsonKey(name: 'all_titles', fromJson: flexibleStringList)
  final List<String>? allTitles;
  final String? url;
  @JsonKey(fromJson: flexibleInt)
  final int? year;

  /// Anime format (`tv`, `movie`, `ova`, ...).
  final String? type;
  final String? poster;
  final SimklIds ids;
  @JsonKey(name: 'ep_count', fromJson: flexibleInt)
  final int? episodeCount;
  final String? status;
  final SimklRatings? ratings;

  const SimklSearchResult({
    this.title,
    this.titleEn,
    this.titleRomaji,
    this.allTitles,
    this.url,
    this.year,
    this.type,
    this.poster,
    required this.ids,
    this.episodeCount,
    this.status,
    this.ratings,
  });

  factory SimklSearchResult.fromJson(Map<String, dynamic> json) => _$SimklSearchResultFromJson(json);
}
