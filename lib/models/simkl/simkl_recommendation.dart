import 'package:json_annotation/json_annotation.dart';

import '../../utils/json_utils.dart';
import 'simkl_ids.dart';

part 'simkl_recommendation.g.dart';

@JsonSerializable(createToJson: false)
class SimklRecommendation {
  final String? title;
  @JsonKey(name: 'en_title')
  final String? englishTitle;
  @JsonKey(fromJson: flexibleInt)
  final int? year;
  final String? poster;
  final String? type;
  @JsonKey(name: 'anime_type')
  final String? animeType;
  @JsonKey(name: 'users_count', fromJson: flexibleInt)
  final int? usersCount;
  @JsonKey(name: 'users_percent')
  final String? usersPercent;
  final SimklIds ids;

  const SimklRecommendation({
    this.title,
    this.englishTitle,
    this.year,
    this.poster,
    this.type,
    this.animeType,
    this.usersCount,
    this.usersPercent,
    required this.ids,
  });

  factory SimklRecommendation.fromJson(Map<String, dynamic> json) => _$SimklRecommendationFromJson(json);
}
