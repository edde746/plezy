import 'package:json_annotation/json_annotation.dart';

import '../../utils/json_utils.dart';
import 'simkl_ids.dart';

part 'simkl_recommendation.g.dart';

@JsonSerializable(createToJson: false)
class SimklRecommendation {
  final String? title;
  @JsonKey(fromJson: flexibleInt)
  final int? year;
  final String? poster;
  final String? type;
  final SimklIds ids;

  const SimklRecommendation({this.title, this.year, this.poster, this.type, required this.ids});

  factory SimklRecommendation.fromJson(Map<String, dynamic> json) => _$SimklRecommendationFromJson(json);
}
