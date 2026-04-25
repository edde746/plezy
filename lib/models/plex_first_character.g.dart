// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plex_first_character.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlexFirstCharacter _$PlexFirstCharacterFromJson(Map<String, dynamic> json) =>
    PlexFirstCharacter(
      key: json['key'] as String? ?? '',
      title: json['title'] as String? ?? '',
      size: (json['size'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$PlexFirstCharacterToJson(PlexFirstCharacter instance) =>
    <String, dynamic>{
      'key': instance.key,
      'title': instance.title,
      'size': instance.size,
    };
