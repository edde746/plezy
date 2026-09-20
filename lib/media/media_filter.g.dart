// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_filter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MediaFilter _$MediaFilterFromJson(Map<String, dynamic> json) => MediaFilter(
  filter: json['filter'] as String? ?? '',
  filterType: json['filterType'] as String? ?? 'string',
  key: json['key'] as String? ?? '',
  title: json['title'] as String? ?? '',
  type: json['type'] as String? ?? 'filter',
);

Map<String, dynamic> _$MediaFilterToJson(MediaFilter instance) =>
    <String, dynamic>{
      'filter': instance.filter,
      'filterType': instance.filterType,
      'key': instance.key,
      'title': instance.title,
      'type': instance.type,
    };

MediaFilterValue _$MediaFilterValueFromJson(Map<String, dynamic> json) =>
    MediaFilterValue(
      key: json['key'] as String? ?? '',
      title: json['title'] as String? ?? '',
      type: json['type'] as String?,
    );

Map<String, dynamic> _$MediaFilterValueToJson(MediaFilterValue instance) =>
    <String, dynamic>{
      'key': instance.key,
      'title': instance.title,
      'type': ?instance.type,
    };
