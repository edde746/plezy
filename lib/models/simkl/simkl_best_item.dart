import 'package:json_annotation/json_annotation.dart';

import '../../utils/json_utils.dart';
import 'simkl_ids.dart';
import 'simkl_rating.dart';

part 'simkl_best_item.g.dart';

@JsonSerializable(createToJson: false)
class SimklBestItem {
  final String? title;
  @JsonKey(fromJson: flexibleInt)
  final int? year;
  final String? poster;
  final SimklIds ids;
  final SimklRatings? ratings;

  const SimklBestItem({this.title, this.year, this.poster, required this.ids, this.ratings});

  factory SimklBestItem.fromJson(Map<String, dynamic> json) => _$SimklBestItemFromJson(json);
}
