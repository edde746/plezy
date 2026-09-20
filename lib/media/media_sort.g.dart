// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_sort.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MediaSort _$MediaSortFromJson(Map<String, dynamic> json) => _MediaSort(
  key: json['key'] as String,
  descKey: json['descKey'] as String?,
  title: json['title'] as String,
  defaultDirection: json['defaultDirection'] as String?,
);

Map<String, dynamic> _$MediaSortToJson(_MediaSort instance) =>
    <String, dynamic>{
      'key': instance.key,
      'descKey': instance.descKey,
      'title': instance.title,
      'defaultDirection': instance.defaultDirection,
    };
