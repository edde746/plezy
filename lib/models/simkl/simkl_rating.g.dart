// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'simkl_rating.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SimklRating _$SimklRatingFromJson(Map<String, dynamic> json) => SimklRating(
  rating: flexibleDouble(json['rating']),
  votes: flexibleInt(json['votes']),
);

SimklRatings _$SimklRatingsFromJson(Map<String, dynamic> json) => SimklRatings(
  simkl: json['simkl'] == null
      ? null
      : SimklRating.fromJson(json['simkl'] as Map<String, dynamic>),
  imdb: json['imdb'] == null
      ? null
      : SimklRating.fromJson(json['imdb'] as Map<String, dynamic>),
  mal: json['mal'] == null
      ? null
      : SimklRating.fromJson(json['mal'] as Map<String, dynamic>),
);
