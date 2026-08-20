// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'simkl_recommendation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SimklRecommendation _$SimklRecommendationFromJson(Map<String, dynamic> json) =>
    SimklRecommendation(
      title: json['title'] as String?,
      englishTitle: json['en_title'] as String?,
      year: flexibleInt(json['year']),
      poster: json['poster'] as String?,
      type: json['type'] as String?,
      animeType: json['anime_type'] as String?,
      usersCount: flexibleInt(json['users_count']),
      usersPercent: json['users_percent'] as String?,
      ids: SimklIds.fromJson(json['ids'] as Map<String, dynamic>),
    );
