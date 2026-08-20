import 'package:json_annotation/json_annotation.dart';

import '../../utils/json_utils.dart';

part 'simkl_rating.g.dart';

@JsonSerializable(createToJson: false)
class SimklRating {
  @JsonKey(fromJson: flexibleDouble)
  final double? rating;
  @JsonKey(fromJson: flexibleInt)
  final int? votes;

  const SimklRating({this.rating, this.votes});

  factory SimklRating.fromJson(Map<String, dynamic> json) => _$SimklRatingFromJson(json);
}

@JsonSerializable(createToJson: false)
class SimklRatings {
  final SimklRating? simkl;
  final SimklRating? imdb;
  final SimklRating? mal;

  const SimklRatings({this.simkl, this.imdb, this.mal});

  SimklRating? get primary => simkl ?? mal ?? imdb;

  factory SimklRatings.fromJson(Map<String, dynamic> json) => _$SimklRatingsFromJson(json);
}
