// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plex_filter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlexFilter _$PlexFilterFromJson(Map<String, dynamic> json) => PlexFilter(
  filter: json['filter'] as String? ?? '',
  filterType: json['filterType'] as String? ?? 'string',
  key: json['key'] as String? ?? '',
  title: json['title'] as String? ?? '',
  type: json['type'] as String? ?? 'filter',
);

Map<String, dynamic> _$PlexFilterToJson(PlexFilter instance) =>
    <String, dynamic>{
      'filter': instance.filter,
      'filterType': instance.filterType,
      'key': instance.key,
      'title': instance.title,
      'type': instance.type,
    };

PlexFilterValue _$PlexFilterValueFromJson(Map<String, dynamic> json) =>
    PlexFilterValue(
      key: json['key'] as String? ?? '',
      title: json['title'] as String? ?? '',
      type: json['type'] as String?,
    );

Map<String, dynamic> _$PlexFilterValueToJson(PlexFilterValue instance) =>
    <String, dynamic>{
      'key': instance.key,
      'title': instance.title,
      'type': ?instance.type,
    };
