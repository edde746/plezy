// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'simkl_recommendation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SimklRecommendation _$SimklRecommendationFromJson(Map<String, dynamic> json) =>
    SimklRecommendation(
      title: json['title'] as String?,
      year: flexibleInt(json['year']),
      poster: json['poster'] as String?,
      type: json['type'] as String?,
      ids: SimklIds.fromJson(json['ids'] as Map<String, dynamic>),
    );
