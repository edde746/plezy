// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'simkl_search_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SimklSearchResult _$SimklSearchResultFromJson(Map<String, dynamic> json) =>
    SimklSearchResult(
      title: json['title'] as String?,
      year: flexibleInt(json['year']),
      type: json['type'] as String?,
      endpointType: json['endpoint_type'] as String?,
      poster: json['poster'] as String?,
      ids: SimklIds.fromJson(json['ids'] as Map<String, dynamic>),
      episodeCount: flexibleInt(json['ep_count']),
      status: json['status'] as String?,
      ratings: json['ratings'] == null
          ? null
          : SimklRatings.fromJson(json['ratings'] as Map<String, dynamic>),
    );
