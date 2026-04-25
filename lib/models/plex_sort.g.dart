// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plex_sort.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlexSort _$PlexSortFromJson(Map<String, dynamic> json) => PlexSort(
  key: json['key'] as String,
  descKey: json['descKey'] as String?,
  title: json['title'] as String,
  defaultDirection: json['defaultDirection'] as String?,
);

Map<String, dynamic> _$PlexSortToJson(PlexSort instance) => <String, dynamic>{
  'key': instance.key,
  'descKey': instance.descKey,
  'title': instance.title,
  'defaultDirection': instance.defaultDirection,
};
