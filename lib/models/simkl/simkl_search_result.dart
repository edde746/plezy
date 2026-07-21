import 'package:json_annotation/json_annotation.dart';

import '../../utils/json_utils.dart';
import 'simkl_ids.dart';
import 'simkl_rating.dart';

part 'simkl_search_result.g.dart';

@JsonSerializable(createToJson: false)
class SimklSearchResult {
  final String? title;
  @JsonKey(fromJson: flexibleInt)
  final int? year;

  /// Anime format (`tv`, `movie`, `ova`, ...).
  final String? type;
  @JsonKey(name: 'endpoint_type')
  final String? endpointType;
  final String? poster;
  final SimklIds ids;
  @JsonKey(name: 'ep_count', fromJson: flexibleInt)
  final int? episodeCount;
  final String? status;
  final SimklRatings? ratings;

  const SimklSearchResult({
    this.title,
    this.year,
    this.type,
    this.endpointType,
    this.poster,
    required this.ids,
    this.episodeCount,
    this.status,
    this.ratings,
  });

  factory SimklSearchResult.fromJson(Map<String, dynamic> json) => _$SimklSearchResultFromJson(json);
}
