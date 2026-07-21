// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'simkl_best_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SimklBestItem _$SimklBestItemFromJson(Map<String, dynamic> json) =>
    SimklBestItem(
      title: json['title'] as String?,
      year: flexibleInt(json['year']),
      poster: json['poster'] as String?,
      ids: SimklIds.fromJson(json['ids'] as Map<String, dynamic>),
      ratings: json['ratings'] == null
          ? null
          : SimklRatings.fromJson(json['ratings'] as Map<String, dynamic>),
    );
